//SystemVerilog
module sync_decoder_async_reset (
    input clk,
    input arst_n,
    input [2:0] address,
    output reg [7:0] cs_n
);
    // Pipeline stage 1 registers
    reg [2:0] address_stage1;
    reg valid_stage1;
    
    // Pipeline stage 2 registers
    reg [2:0] address_stage2;
    reg valid_stage2;
    
    // Pipeline stage 3 registers
    reg [2:0] address_stage3;
    reg valid_stage3;
    
    // Pipeline stage 1: Input registration
    always @(posedge clk or negedge arst_n) begin
        if (!arst_n) begin
            address_stage1 <= 3'b0;
            valid_stage1 <= 1'b0;
        end
        else begin
            address_stage1 <= address;
            valid_stage1 <= 1'b1;
        end
    end
    
    // Pipeline stage 2: Address propagation
    always @(posedge clk or negedge arst_n) begin
        if (!arst_n) begin
            address_stage2 <= 3'b0;
            valid_stage2 <= 1'b0;
        end
        else begin
            address_stage2 <= address_stage1;
            valid_stage2 <= valid_stage1;
        end
    end
    
    // Pipeline stage 3: Shift computation
    always @(posedge clk or negedge arst_n) begin
        if (!arst_n) begin
            address_stage3 <= 3'b0;
            valid_stage3 <= 1'b0;
        end
        else begin
            address_stage3 <= address_stage2;
            valid_stage3 <= valid_stage2;
        end
    end
    
    // Pipeline stage 4: Final output generation
    always @(posedge clk or negedge arst_n) begin
        if (!arst_n)
            cs_n <= 8'hFF;
        else if (valid_stage3)
            cs_n <= ~(8'h01 << address_stage3);
    end
endmodule