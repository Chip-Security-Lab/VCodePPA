//SystemVerilog
module sync_decoder_async_reset_pipelined (
    input clk,
    input arst_n,
    input [2:0] address,
    output reg [7:0] cs_n
);

    // Pipeline stage 1: Address register
    reg [2:0] address_stage1;
    
    // Pipeline stage 2: Shift operation
    reg [7:0] shift_result_stage2;
    
    // Pipeline stage 3: Inversion and output
    reg [7:0] inverted_result_stage3;

    // Stage 1: Register input address
    always @(posedge clk or negedge arst_n) begin
        if (!arst_n)
            address_stage1 <= 3'b0;
        else
            address_stage1 <= address;
    end

    // Stage 2: Perform shift operation
    always @(posedge clk or negedge arst_n) begin
        if (!arst_n)
            shift_result_stage2 <= 8'h00;
        else
            shift_result_stage2 <= 8'h01 << address_stage1;
    end

    // Stage 3: Invert and output
    always @(posedge clk or negedge arst_n) begin
        if (!arst_n)
            inverted_result_stage3 <= 8'hFF;
        else
            inverted_result_stage3 <= ~shift_result_stage2;
    end

    // Output assignment
    assign cs_n = inverted_result_stage3;

endmodule