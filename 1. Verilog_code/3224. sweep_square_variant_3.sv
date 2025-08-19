//SystemVerilog
module sweep_square(
    input clk,
    input rst,
    input [7:0] start_period,
    input [7:0] end_period,
    input [15:0] sweep_rate,
    input data_ready,       // 接收方准备好接收数据的信号
    output reg data_valid,  // 数据有效信号
    output reg sq_out
);
    reg [7:0] period;
    reg [7:0] counter;
    reg [15:0] sweep_counter;
    reg sweep_dir;  // 0: increasing frequency, 1: decreasing
    reg output_ready;
    
    always @(posedge clk) begin
        if (rst) begin
            period <= start_period;
            counter <= 8'd0;
            sweep_counter <= 16'd0;
            sweep_dir <= 1'b0;
            sq_out <= 1'b0;
            data_valid <= 1'b0;
            output_ready <= 1'b1;
        end else begin
            // 数据有效状态管理
            if (data_valid && data_ready) begin
                data_valid <= 1'b0;  // 握手完成，取消有效信号
            end
            
            // Counter for generating square wave
            if (counter >= period-1) begin
                counter <= 8'd0;
                sq_out <= ~sq_out;
                // 当方波发生变化时，将数据标记为有效
                if (output_ready) begin
                    data_valid <= 1'b1;
                    output_ready <= 1'b0;
                end
            end else begin
                counter <= counter + 8'd1;
                // 在非边沿区域恢复ready状态
                if (!data_valid) begin
                    output_ready <= 1'b1;
                end
            end
            
            // Counter for frequency sweep
            if (sweep_counter >= sweep_rate-1) begin
                sweep_counter <= 16'd0;
                
                if (!sweep_dir) begin
                    if (period <= end_period)
                        sweep_dir <= 1'b1;
                    else
                        period <= period - 8'd1;
                end else begin
                    if (period >= start_period)
                        sweep_dir <= 1'b0;
                    else
                        period <= period + 8'd1;
                end
            end else begin
                sweep_counter <= sweep_counter + 16'd1;
            end
        end
    end
endmodule