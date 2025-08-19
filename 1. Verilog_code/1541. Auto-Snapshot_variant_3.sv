//SystemVerilog - IEEE 1364-2005
module auto_snapshot_shadow_reg #(
    parameter WIDTH = 16
)(
    input wire clk,
    input wire rst_n,
    input wire [WIDTH-1:0] data_in,
    input wire error_detected,
    output reg [WIDTH-1:0] shadow_data,
    output reg snapshot_taken,
    // 流水线控制信号
    input wire valid_in,
    output wire ready_in,
    output reg valid_out,
    input wire ready_out
);
    // 流水线阶段寄存器与控制信号
    reg [WIDTH-1:0] stage1_data;
    reg [WIDTH-1:0] stage2_data;
    reg stage1_valid, stage2_valid;
    reg stage1_error, stage2_error;
    reg stage1_snapshot_status, stage2_snapshot_status;
    
    // 流水线反压控制
    wire stage2_ready;
    wire stage1_ready;
    
    assign stage2_ready = !stage2_valid || ready_out;
    assign stage1_ready = !stage1_valid || stage2_ready;
    assign ready_in = stage1_ready;
    
    // 第一级流水线：数据捕获
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            stage1_data <= {WIDTH{1'b0}};
            stage1_valid <= 1'b0;
            stage1_error <= 1'b0;
            stage1_snapshot_status <= 1'b0;
        end else if (stage1_ready) begin
            if (valid_in) begin
                stage1_data <= data_in;
                stage1_valid <= 1'b1;
                stage1_error <= error_detected;
                stage1_snapshot_status <= snapshot_taken;
            end else begin
                stage1_valid <= 1'b0;
            end
        end
    end
    
    // 第二级流水线：错误检测和快照逻辑
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            stage2_data <= {WIDTH{1'b0}};
            stage2_valid <= 1'b0;
            stage2_error <= 1'b0;
            stage2_snapshot_status <= 1'b0;
        end else if (stage2_ready) begin
            if (stage1_valid) begin
                stage2_data <= stage1_data;
                stage2_valid <= stage1_valid;
                stage2_error <= stage1_error;
                stage2_snapshot_status <= stage1_snapshot_status;
            end else begin
                stage2_valid <= 1'b0;
            end
        end
    end
    
    // 输出级：处理错误和快照逻辑
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            shadow_data <= {WIDTH{1'b0}};
            snapshot_taken <= 1'b0;
            valid_out <= 1'b0;
        end else if (ready_out) begin
            if (stage2_valid) begin
                valid_out <= 1'b1;
                
                if (!stage2_error) begin
                    snapshot_taken <= 1'b0;
                end else if (!stage2_snapshot_status) begin
                    shadow_data <= stage2_data;
                    snapshot_taken <= 1'b1;
                end
            end else begin
                valid_out <= 1'b0;
            end
        end
    end
endmodule