//SystemVerilog
module shadow_reg_fsm #(parameter DW=4) (
    input clk, rst, trigger,
    input [DW-1:0] data_in,
    output reg [DW-1:0] data_out,
    output reg ready
);
    // Pipeline stages
    reg [1:0] stage_valid;
    reg [DW-1:0] data_stage1;
    
    // Pipeline control
    wire stage1_ready;
    wire stage2_ready;
    
    // Stage ready signals (backpressure handling)
    assign stage1_ready = ~stage_valid[0] | stage2_ready;
    assign stage2_ready = ~stage_valid[1] | ready;
    
    // Pipeline stage 1: Input capture
    always @(posedge clk) begin
        if (rst) begin
            stage_valid[0] <= 1'b0;
            data_stage1 <= {DW{1'b0}};
        end else if (stage1_ready) begin
            if (trigger) begin
                stage_valid[0] <= 1'b1;
                data_stage1 <= data_in;
            end else begin
                stage_valid[0] <= 1'b0;
            end
        end
    end
    
    // Pipeline stage 2: Output generation
    always @(posedge clk) begin
        if (rst) begin
            stage_valid[1] <= 1'b0;
            data_out <= {DW{1'b0}};
        end else if (stage2_ready) begin
            stage_valid[1] <= stage_valid[0];
            if (stage_valid[0]) begin
                data_out <= data_stage1;
            end
        end
    end
    
    // Ready signal generation
    always @(posedge clk) begin
        if (rst) begin
            ready <= 1'b1;
        end else begin
            // Toggle ready based on pipeline state
            if (stage_valid[1]) begin
                ready <= 1'b0;
            end else begin
                ready <= 1'b1;
            end
        end
    end
endmodule