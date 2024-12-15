`timescale 1ns/1ps

module Top_module_tb;

    // Testbench Inputs and Outputs
    logic clk;
    logic reset;
    tri dht11_data; // Bi-directional data line for DHT11
    logic [6:0] hex0;
    logic [6:0] hex1;
    logic [6:0] hex2;
    logic [6:0] hex3;

    // Internal signals for mocking the DHT11
    logic dht11_data_drive;
    logic dht11_data_in;
    assign dht11_data = dht11_data_drive ? dht11_data_in : 1'bz; // Simulate tri-state behavior

    // Instantiate the Top_module
    Top_module uut (
        .clk(clk),
        .reset(reset),
        .dht11_data(dht11_data),
        .hex0(hex0),
        .hex1(hex1),
        .hex2(hex2),
        .hex3(hex3)
    );

    // Clock generation
    always #5 clk = ~clk; // 10ns clock period (100 MHz)

    // Task to simulate DHT11 response
    task send_dht11_data(input [39:0] data);
        integer i;
        begin
            // Pull data low for start signal
            dht11_data_drive = 1;
            dht11_data_in = 0;
            #(18000); // 18ms low

            // Release data for response period
            dht11_data_drive = 0;
            #(80); // 80us high from DHT11

            // Drive each bit of data (40 bits: humidity[15:8], humidity[7:0], temperature[15:8], temperature[7:0], checksum)
            for (i = 0; i < 40; i++) begin
                dht11_data_drive = 1;
                dht11_data_in = 0;
                #(50); // 50us low

                dht11_data_in = data[39 - i]; // Send the bit (1 or 0)
                #(70); // 70us high for 1, shorter for 0
            end

            // Release the line
            dht11_data_drive = 0;
        end
    endtask

    // Initialize testbench signals
    initial begin
        clk = 0;
        reset = 1;
        dht11_data_drive = 0;
        dht11_data_in = 1;

        // Apply reset
        #20;
        reset = 0;

        // Test Case 1: Valid data
        #100;
        $display("Test Case 1: Sending valid data...");
        send_dht11_data(40'h645A32CC); // Example: Humidity = 100, Temperature = 50, Checksum = 0xCC

        // Wait for processing
        #50000;

        // Check the outputs
        $display("HEX0: %b", hex0);
        $display("HEX1: %b", hex1);
        $display("HEX2: %b", hex2);
        $display("HEX3: %b", hex3);

        // Test Case 2: Invalid checksum
        #100;
        $display("Test Case 2: Sending invalid checksum data...");
        send_dht11_data(40'h645A32AB); // Invalid checksum

        // Wait for processing
        #50000;

        // Check the outputs (should be blank or error state)
        $display("HEX0: %b", hex0);
        $display("HEX1: %b", hex1);
        $display("HEX2: %b", hex2);
        $display("HEX3: %b", hex3);

        // Finish simulation
        #100;
        $stop;
    end

    // Debugging Block
    initial begin
        $display("Simulation started.");
        #50000; // Wait for some time
        $display("Checking outputs after 50us...");
        $display("HEX0: %b, HEX1: %b, HEX2: %b, HEX3: %b", hex0, hex1, hex2, hex3);
    end

endmodule

