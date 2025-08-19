module cam_9 (
    input wire clk,
    input wire rst,         // 添加复位信号
    input wire [7:0] data_in,
    output reg match_flag,
    output reg [7:0] stored_data
);
    // 状态定义
    localparam IDLE = 2'b00,
              COMPARE = 2'b01;
    
    reg [1:0] state;
    
    // 添加复位逻辑
    always @(posedge clk) begin
        if (rst) begin
            state <= IDLE;
            stored_data <= 8'b0;
            match_flag <= 1'b0;
        end else begin
            case (state)
                IDLE: begin
                    stored_data <= data_in;
                    state <= COMPARE;
                end
                COMPARE: begin
                    match_flag <= (stored_data == data_in);
                    state <= IDLE;
                end
                default: state <= IDLE; // 添加默认状态
            endcase
        end
    end
endmodule