//SystemVerilog
module xor_async_rst(
    input  wire        clk,      // Clock input
    input  wire        rst_n,    // Active-low asynchronous reset
    input  wire        a,        // Data input A
    input  wire        b,        // Data input B
    input  wire        valid_in, // Input valid signal
    output reg         valid_out,// Output valid signal
    output reg         y         // XOR result output
);
    // Pipeline stage registers with reset logic combined
    reg [1:0] data_stage1, data_stage2;
    reg [1:0] data_stage3;
    reg valid_stage1, valid_stage2, valid_stage3;
    
    // Combined pipeline register update with optimized bit packing
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            // Reset all pipeline registers in a single block
            {data_stage1, data_stage2, data_stage3} <= 6'b0;
            {valid_stage1, valid_stage2, valid_stage3, valid_out} <= 4'b0;
            y <= 1'b0;
        end
        else begin
            // Stage 1: Pack input data into a single register
            data_stage1 <= {a, b};
            valid_stage1 <= valid_in;
            
            // Stage 2: Forward packed data
            data_stage2 <= data_stage1;
            valid_stage2 <= valid_stage1;
            
            // Stage 3: Compute XOR and store result
            data_stage3[0] <= data_stage2[0] ^ data_stage2[1];
            valid_stage3 <= valid_stage2;
            
            // Stage 4: Output registration
            y <= data_stage3[0];
            valid_out <= valid_stage3;
        end
    end
endmodule