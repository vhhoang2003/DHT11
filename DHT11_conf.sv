module DHT11 (
    input logic clk,            // Clock input
    input logic reset,          // Reset input
    inout logic data,           // Bi-directional data line
    output logic [7:0] humidity,   // 8-bit humidity output
    output logic [7:0] temperature, // 8-bit temperature output
    output logic valid            // Valid flag for data
);
    
    // State machine states (using typedef enum for better readability)
    typedef enum logic [2:0] {
        IDLE       = 3'b000,
        START      = 3'b001,
        RESPONSE   = 3'b010,
        READ_DATA  = 3'b011,
        PROCESS    = 3'b100
    } state_t;
    
    state_t current_state, next_state;
    logic data_out;             // Data line output control
    logic [39:0] data_buffer;   // 40-bit data buffer
    logic [5:0] bit_index;      // Index for bits being read
    logic [19:0] counter;       // Counter for timing purposes
    logic data_prev;            // Previous state for edge detection
    
    // Timing parameters (in clock cycles)
    parameter START_LOW = 16'd9;      // 18 ms
    parameter RESPONSE_WAIT = 4000;    // 80 µs
    parameter IDLE_WAIT = 1000;        // Idle wait time

    // Assignments
    assign data = (data_out) ? 1'bz : 1'b0;  // Tri-state data line
    
    // Control signals based on counter values
  logic start_condition, response_received, idle_wait_completed;

// Compute control signals based on counter values
	always_comb begin
			start_condition = (counter >= START_LOW);
			response_received = (counter >= RESPONSE_WAIT);
			idle_wait_completed = (counter >= IDLE_WAIT);
	end
    // Edge detection for rising edge of data signal
    wire data_signal_detected = (data_prev == 0 && data == 1);

    // Counter Logic (synchronous reset and counting)
    always_ff @(posedge clk or posedge reset) begin
        if (reset) begin
            counter <= 0;
        end else if (current_state != next_state) begin
            counter <= 0;
        end else begin
            counter <= counter + 1;
        end
    end

    // State machine logic (transitioning between states)
    always_ff @(posedge clk or posedge reset) begin
        if (reset) begin
            current_state <= IDLE;
        end else begin
            current_state <= next_state;
        end
    end

    // State transition logic (combinational logic)
    always_comb begin
        case (current_state)
            IDLE: begin
                if (idle_wait_completed) next_state = START;
                else next_state = IDLE;
            end
            START: begin
                if (counter >= START_LOW) next_state = RESPONSE;
                else next_state = START;
            end
            RESPONSE: begin
                if (response_received) next_state = READ_DATA;
                else next_state = RESPONSE;
            end
            READ_DATA: begin
                if (bit_index == 40) next_state = PROCESS;
                else next_state = READ_DATA;
            end
            PROCESS: begin
                next_state = IDLE;
            end
            default: next_state = IDLE;
        endcase
    end

    // Control for data output (driving the data line)
    always_ff @(posedge clk or posedge reset) begin
        if (reset) begin
            data_out <= 1;
        end else if (current_state == START && counter < START_LOW) begin
            data_out <= 0;
        end else if (current_state == START && counter >= START_LOW) begin
            data_out <= 1;
        end
    end

    // Reading data from DHT11 (shift data into buffer)
    always_ff @(posedge clk or posedge reset) begin
        if (reset) begin
            data_buffer <= 0;
            bit_index <= 0;
        end else if (current_state == READ_DATA) begin
            if (data_signal_detected) begin
                data_buffer[39 - bit_index] <= data; // Shift data into buffer
                bit_index <= bit_index + 1;
            end
        end
    end

    // Processing the data (extract humidity and temperature)
    always_ff @(posedge clk or posedge reset) begin
        if (reset) begin
            humidity <= 0;
            temperature <= 0;
            valid <= 0;
        end else if (current_state == PROCESS) begin
            humidity <= data_buffer[39:32];  // Extract humidity (8 bits)
            temperature <= data_buffer[23:16];  // Extract temperature (8 bits)
            valid <= 1;  // Set valid flag
        end
    end

    // Update previous data state (for edge detection)
    always_ff @(posedge clk) begin
        data_prev <= data;
    end

endmodule
