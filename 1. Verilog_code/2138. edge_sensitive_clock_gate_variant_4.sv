//SystemVerilog
module edge_sensitive_clock_gate (
    input  wire clk_in,
    input  wire valid_in,
    input  wire rst_n,
    output wire ready_out,
    output wire clk_out,
    output wire valid_out
);
    reg valid_in_registered;
    reg busy;
    wire edge_detected;
    
    // 扁平化if-else结构的状态捕获逻辑
    always @(posedge clk_in or negedge rst_n) begin
        if (!rst_n) begin
            valid_in_registered <= 1'b0;
            busy <= 1'b0;
        end
        else if (!busy) begin
            valid_in_registered <= valid_in;
            busy <= valid_in && !valid_in_registered;
        end
        else begin
            valid_in_registered <= valid_in_registered;
            busy <= busy;
        end
    end
    
    // 优化边沿检测逻辑 - 减少组合逻辑链
    assign edge_detected = valid_in && !valid_in_registered && !busy;
    
    // 优化输出逻辑
    assign clk_out = edge_detected ? clk_in : 1'b0;
    assign ready_out = !busy;
    assign valid_out = edge_detected;
    
endmodule