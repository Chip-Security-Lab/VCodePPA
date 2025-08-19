//SystemVerilog
module binary_to_onehot_sync #(parameter ADDR_WIDTH = 4) (
    input                       clk,
    input                       rst_n,
    input                       enable,
    input      [ADDR_WIDTH-1:0] binary_in,
    output reg [2**ADDR_WIDTH-1:0] onehot_out
);
    // Internal signals for borrow subtractor implementation
    reg [ADDR_WIDTH-1:0] internal_count;
    reg [ADDR_WIDTH-1:0] subtractor_result;
    reg subtract_mode;
    
    // Borrow subtractor signals
    reg [ADDR_WIDTH:0] borrow;  // Extra bit for final borrow out
    reg [ADDR_WIDTH-1:0] minuend;
    reg [ADDR_WIDTH-1:0] subtrahend;
    
    // Main sequential logic
    always @(posedge clk) begin
        if (!rst_n) begin
            onehot_out <= {(2**ADDR_WIDTH){1'b0}};
            internal_count <= {ADDR_WIDTH{1'b0}};
            subtract_mode <= 1'b0;
            subtractor_result <= {ADDR_WIDTH{1'b0}};
            borrow <= {(ADDR_WIDTH+1){1'b0}};
        end else if (enable) begin
            // Determine subtraction mode based on input value
            subtract_mode <= binary_in[ADDR_WIDTH-1];
            
            // Set minuend and subtrahend based on mode
            minuend = internal_count;
            subtrahend = binary_in;
            
            // Implement borrow subtractor algorithm
            borrow[0] = 1'b0; // Initial borrow is 0
            for (int i = 0; i < ADDR_WIDTH; i = i + 1) begin
                subtractor_result[i] = minuend[i] ^ subtrahend[i] ^ borrow[i];
                borrow[i+1] = (~minuend[i] & subtrahend[i]) | 
                             (~minuend[i] & borrow[i]) | 
                             (subtrahend[i] & borrow[i]);
            end
            
            // Adjust result based on subtract mode if needed
            if (subtract_mode) begin
                internal_count <= subtractor_result;
            end
            
            // Convert to one-hot encoding - unchanged functionality
            onehot_out <= {{(2**ADDR_WIDTH-1){1'b0}}, 1'b1} << binary_in;
        end
    end
endmodule