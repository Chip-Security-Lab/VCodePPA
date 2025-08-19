//SystemVerilog
module AutoBaudUART (
    input clk, rst_n,
    input rx_line,
    output reg [15:0] baud_rate,
    output reg baud_locked
);
    // 使用独热编码定义状态
    localparam [3:0] 
        SEARCH = 4'b0001,
        MEASURE = 4'b0010,
        LOCKED = 4'b0100,
        IDLE = 4'b1000;
    
    reg [3:0] current_state;
    reg [15:0] edge_counter;
    reg last_rx;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            current_state <= SEARCH;
            edge_counter <= 0;
            last_rx <= 1;
            baud_locked <= 0;
            baud_rate <= 0;
        end else begin
            last_rx <= rx_line;
            case(current_state)
                SEARCH: begin
                    if (last_rx == 1'b1 && rx_line == 1'b0) begin
                        current_state <= MEASURE;
                        edge_counter <= 0;
                    end
                end
                MEASURE: begin
                    edge_counter <= edge_counter + 1;
                    if (last_rx == 1'b0 && rx_line == 1'b1) begin
                        baud_rate <= edge_counter;
                        current_state <= LOCKED;
                    end
                end
                LOCKED: begin
                    baud_locked <= 1;
                end
                default: current_state <= SEARCH;
            endcase
        end
    end
endmodule