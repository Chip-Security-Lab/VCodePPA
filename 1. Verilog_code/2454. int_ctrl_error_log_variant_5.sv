//SystemVerilog
module int_ctrl_error_log #(
    parameter ERR_BITS = 4
)(
    input wire clk,
    input wire rst,
    input wire [ERR_BITS-1:0] err_in,
    input wire valid_in,
    output wire valid_out,
    output wire [ERR_BITS-1:0] err_log
);

    // Pipeline stage 1 registers
    reg [ERR_BITS-1:0] err_in_stage1;
    reg valid_stage1;
    
    // Pipeline stage 2 registers
    reg [ERR_BITS-1:0] err_log_stage2;
    reg valid_stage2;
    
    // Pipeline stage 3 registers
    reg [ERR_BITS-1:0] err_log_stage3;
    reg valid_stage3;
    
    // Stage 1: Input registration
    always @(posedge clk) begin
        if (rst) begin
            err_in_stage1 <= {ERR_BITS{1'b0}};
            valid_stage1 <= 1'b0;
        end else begin
            err_in_stage1 <= err_in;
            valid_stage1 <= valid_in;
        end
    end
    
    // Stage 2: Error processing and accumulation logic
    always @(posedge clk) begin
        if (rst) begin
            err_log_stage2 <= {ERR_BITS{1'b0}};
            valid_stage2 <= 1'b0;
        end else begin
            if (valid_stage1) begin
                err_log_stage2 <= err_log_stage2 | err_in_stage1;
            end
            valid_stage2 <= valid_stage1;
        end
    end
    
    // Stage 3: Output registration
    always @(posedge clk) begin
        if (rst) begin
            err_log_stage3 <= {ERR_BITS{1'b0}};
            valid_stage3 <= 1'b0;
        end else begin
            err_log_stage3 <= err_log_stage2;
            valid_stage3 <= valid_stage2;
        end
    end
    
    // Output assignments
    assign err_log = err_log_stage3;
    assign valid_out = valid_stage3;

endmodule