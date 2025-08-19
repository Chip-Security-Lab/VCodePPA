//SystemVerilog
module multisource_timer #(
    parameter COUNTER_WIDTH = 16
)(
    input wire clk_src_0,
    input wire clk_src_1,
    input wire clk_src_2,
    input wire clk_src_3,
    input wire [1:0] clk_sel,
    input wire rst_n,
    input wire [COUNTER_WIDTH-1:0] threshold,
    output reg event_out
);
    reg [COUNTER_WIDTH-1:0] counter_0, counter_1, counter_2, counter_3;
    reg event_out_0, event_out_1, event_out_2, event_out_3;
    
    // 独立时钟域处理，将时钟选择逻辑移到后端
    // 时钟源 0 逻辑
    always @(posedge clk_src_0 or negedge rst_n) begin
        if (!rst_n) begin
            counter_0 <= {COUNTER_WIDTH{1'b0}};
            event_out_0 <= 1'b0;
        end else begin
            if (counter_0 >= threshold - 1) begin
                counter_0 <= {COUNTER_WIDTH{1'b0}};
                event_out_0 <= 1'b1;
            end else begin
                counter_0 <= counter_0 + 1'b1;
                event_out_0 <= 1'b0;
            end
        end
    end
    
    // 时钟源 1 逻辑
    always @(posedge clk_src_1 or negedge rst_n) begin
        if (!rst_n) begin
            counter_1 <= {COUNTER_WIDTH{1'b0}};
            event_out_1 <= 1'b0;
        end else begin
            if (counter_1 >= threshold - 1) begin
                counter_1 <= {COUNTER_WIDTH{1'b0}};
                event_out_1 <= 1'b1;
            end else begin
                counter_1 <= counter_1 + 1'b1;
                event_out_1 <= 1'b0;
            end
        end
    end
    
    // 时钟源 2 逻辑
    always @(posedge clk_src_2 or negedge rst_n) begin
        if (!rst_n) begin
            counter_2 <= {COUNTER_WIDTH{1'b0}};
            event_out_2 <= 1'b0;
        end else begin
            if (counter_2 >= threshold - 1) begin
                counter_2 <= {COUNTER_WIDTH{1'b0}};
                event_out_2 <= 1'b1;
            end else begin
                counter_2 <= counter_2 + 1'b1;
                event_out_2 <= 1'b0;
            end
        end
    end
    
    // 时钟源 3 逻辑
    always @(posedge clk_src_3 or negedge rst_n) begin
        if (!rst_n) begin
            counter_3 <= {COUNTER_WIDTH{1'b0}};
            event_out_3 <= 1'b0;
        end else begin
            if (counter_3 >= threshold - 1) begin
                counter_3 <= {COUNTER_WIDTH{1'b0}};
                event_out_3 <= 1'b1;
            end else begin
                counter_3 <= counter_3 + 1'b1;
                event_out_3 <= 1'b0;
            end
        end
    end
    
    // 输出选择逻辑（组合逻辑）
    always @(*) begin
        case (clk_sel)
            2'b00: event_out = event_out_0;
            2'b01: event_out = event_out_1;
            2'b10: event_out = event_out_2;
            2'b11: event_out = event_out_3;
            default: event_out = event_out_0;
        endcase
    end
    
endmodule