module Top_module  (
    input logic clk,               // Clock input
    input logic reset,             // Reset input
    inout wire dht11_data,        // Bi-directional data line for DHT11
    output logic [6:0] hex0,       // 7-segment display for upper nibble of humidity
    output logic [6:0] hex1,       // 7-segment display for lower nibble of humidity
    output logic [6:0] hex2,       // 7-segment display for upper nibble of temperature
    output logic [6:0] hex3        // 7-segment display for lower nibble of temperature
);

    // Internal signals to store humidity and temperature
    wire [7:0] humidity;
    wire [7:0] temperature;
    
    // Internal signals for controlling DHT11 data line
    logic dht11_data_out;           // Control signal for output to dht11_data
    logic dht11_data_in;            // Internal signal for input from dht11_data

    // DHT11 sensor interface instance
    DHT11 dht11_inst (
        .clk(clk),
        .reset(reset),
        .data(dht11_data),       // Connect to internal signal for input
        .humidity(humidity),
        .temperature(temperature)
    );

    // Control the bidirectional dht11_data line
    // Tri-state buffer: drive dht11_data when dht11_data_out is active, else high-z
    assign dht11_data = (dht11_data_out) ? 1'b0 : dht11_data_in;  // When driving, use high-Z for receiving

    // HEX display instances for displaying humidity and temperature
    HEX hex0_inst (
        .value(humidity[7:4]),       // Upper nibble of humidity
        .hex(hex0)
    );

    HEX hex1_inst (
        .value(humidity[3:0]),       // Lower nibble of humidity
        .hex(hex1)
    );

    HEX hex2_inst (
        .value(temperature[7:4]),    // Upper nibble of temperature
        .hex(hex2)
    );

    HEX hex3_inst (
        .value(temperature[3:0]),    // Lower nibble of temperature
        .hex(hex3)
    );

endmodule
