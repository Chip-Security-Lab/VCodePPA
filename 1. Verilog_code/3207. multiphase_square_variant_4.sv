//SystemVerilog
module multiphase_square(
    input wire clock,
    input wire reset_n,
    input wire [7:0] period,
    input wire valid,
    output wire ready,
    output reg [3:0] phase_outputs
);
    reg [7:0] count;
    reg period_loaded;
    reg [7:0] period_reg;
    
    // 当valid高且ready高时完成握手
    assign ready = !period_loaded || (count >= period_reg-1);
    
    always @(posedge clock or negedge reset_n) begin
        if (!reset_n) begin
            count <= 8'd0;
            phase_outputs <= 4'b0001;
            period_loaded <= 1'b0;
            period_reg <= 8'd0;
        end else begin
            if (valid && ready) begin
                // 完成握手，加载新周期值
                period_reg <= period;
                period_loaded <= 1'b1;
                // 如果是在计数完成时加载新值，重置计数并旋转输出
                if (count >= period_reg-1) begin
                    count <= 8'd0;
                    phase_outputs <= {phase_outputs[2:0], phase_outputs[3]};
                end
            end else if (period_loaded && count >= period_reg-1) begin
                // 计数完成，重置计数并旋转输出
                count <= 8'd0;
                phase_outputs <= {phase_outputs[2:0], phase_outputs[3]};
            end else if (period_loaded) begin
                // 正常计数
                count <= count + 1'b1;
            end
        end
    end
endmodule