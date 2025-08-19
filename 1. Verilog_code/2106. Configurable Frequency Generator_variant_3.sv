//SystemVerilog
module config_freq_gen_req_ack(
    input wire master_clk,
    input wire rstn,
    input wire [7:0] freq_sel,
    input wire req,         // 请求信号
    output reg ack,         // 应答信号
    output reg out_clk
);

    reg [7:0] counter;
    reg counter_reset;
    reg toggle_out_clk;
    reg req_latched;

    // 请求信号锁存，提高PPA和时序稳定性
    always @(posedge master_clk or negedge rstn) begin
        if (!rstn) begin
            req_latched <= 1'b0;
        end else begin
            req_latched <= req;
        end
    end

    // Counter control logic
    always @(*) begin
        if (counter >= freq_sel) begin
            counter_reset = 1'b1;
            toggle_out_clk = 1'b1;
        end else begin
            counter_reset = 1'b0;
            toggle_out_clk = 1'b0;
        end
    end

    // Counter register update
    always @(posedge master_clk or negedge rstn) begin
        if (!rstn) begin
            counter <= 8'd0;
        end else if (counter_reset && req_latched) begin
            counter <= 8'd0;
        end else if (req_latched) begin
            counter <= counter + 8'd1;
        end
    end

    // Output clock update logic
    always @(posedge master_clk or negedge rstn) begin
        if (!rstn) begin
            out_clk <= 1'b0;
        end else if (toggle_out_clk && req_latched) begin
            out_clk <= ~out_clk;
        end
    end

    // Ack信号生成逻辑
    // ack在一个周期内有效，指示数据已被处理
    always @(posedge master_clk or negedge rstn) begin
        if (!rstn) begin
            ack <= 1'b0;
        end else if (counter_reset && req_latched) begin
            ack <= 1'b1;
        end else begin
            ack <= 1'b0;
        end
    end

endmodule