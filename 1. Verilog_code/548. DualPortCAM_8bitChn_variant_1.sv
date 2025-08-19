//SystemVerilog
module cam_8 (
    input wire clk,
    input wire rst,
    input wire write_en,
    input wire [7:0] port1_data,
    input wire [7:0] port2_data,
    output reg port1_match,
    output reg port2_match
);
    reg [7:0] stored_port1, stored_port2;
    reg [1:0] state;
    reg [1:0] state_buf;
    reg [7:0] port1_data_buf, port2_data_buf;
    reg write_en_buf;
    
    // 输入信号缓冲
    always @(posedge clk) begin
        port1_data_buf <= port1_data;
        port2_data_buf <= port2_data;
        write_en_buf <= write_en;
    end
    
    // 状态机逻辑
    always @(posedge clk) begin
        if (rst) begin
            state <= 2'b00;
            state_buf <= 2'b00;
        end else begin
            case (state_buf)
                2'b00: begin
                    if (write_en_buf) begin
                        state <= 2'b01;
                    end else begin
                        state <= 2'b10;
                    end
                end
                2'b01: begin
                    state <= 2'b00;
                end
                2'b10: begin
                    state <= 2'b00;
                end
                default: state <= 2'b00;
            endcase
            state_buf <= state;
        end
    end
    
    // 数据处理逻辑
    always @(posedge clk) begin
        case (state_buf)
            2'b00: begin
                if (rst) begin
                    stored_port1 <= 8'b0;
                    stored_port2 <= 8'b0;
                    port1_match <= 1'b0;
                    port2_match <= 1'b0;
                end
            end
            2'b01: begin
                stored_port1 <= port1_data_buf;
                stored_port2 <= port2_data_buf;
            end
            2'b10: begin
                port1_match <= (stored_port1 == port1_data_buf);
                port2_match <= (stored_port2 == port2_data_buf);
            end
            default: begin
                stored_port1 <= stored_port1;
                stored_port2 <= stored_port2;
                port1_match <= port1_match;
                port2_match <= port2_match;
            end
        endcase
    end
endmodule