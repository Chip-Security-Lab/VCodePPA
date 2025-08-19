//SystemVerilog
module ICMU_PipelineFSM #(
    parameter STAGES = 3,
    parameter DW = 32
)(
    input clk,
    input rst_async,
    input int_req,
    output reg [DW-1:0] ctx_out,
    output reg ctx_valid
);
    localparam IDLE = 2'b00;
    localparam SAVE_PIPE = 2'b01;
    localparam RESTORE_PIPE = 2'b10;
    
    reg [1:0] state_stage1, state_stage2, state_stage3;
    reg [DW-1:0] data_stage1, data_stage2, data_stage3;
    reg valid_stage1, valid_stage2, valid_stage3;
    
    // 2-bit two's complement subtractor
    wire [1:0] sub_result;
    wire [1:0] sub_a = state_stage1[1:0];
    wire [1:0] sub_b = {2{1'b1}};
    wire [1:0] sub_b_comp = ~sub_b + 1'b1;
    assign sub_result = sub_a + sub_b_comp;
    
    always @(posedge clk or posedge rst_async) begin
        if (rst_async) begin
            state_stage1 <= IDLE;
            data_stage1 <= 0;
            valid_stage1 <= 0;
        end else begin
            state_stage1 <= int_req ? SAVE_PIPE : sub_result;
            data_stage1 <= {DW{1'b1}};
            valid_stage1 <= 1'b1;
        end
    end
    
    always @(posedge clk or posedge rst_async) begin
        if (rst_async) begin
            state_stage2 <= IDLE;
            data_stage2 <= 0;
            valid_stage2 <= 0;
        end else begin
            state_stage2 <= state_stage1;
            data_stage2 <= data_stage1;
            valid_stage2 <= valid_stage1;
        end
    end
    
    always @(posedge clk or posedge rst_async) begin
        if (rst_async) begin
            state_stage3 <= IDLE;
            data_stage3 <= 0;
            valid_stage3 <= 0;
            ctx_valid <= 0;
            ctx_out <= 0;
        end else begin
            state_stage3 <= state_stage2;
            data_stage3 <= data_stage2;
            valid_stage3 <= valid_stage2;
            ctx_valid <= (state_stage3 == SAVE_PIPE) && valid_stage3;
            ctx_out <= data_stage3;
        end
    end
endmodule