//SystemVerilog
module packet_buf #(parameter DW=8) (
    input wire clk, rst_n,
    input wire [DW-1:0] din,
    input wire din_valid,
    output reg [DW-1:0] dout,
    output reg pkt_valid
);
    localparam [7:0] DELIMITER = 8'hFF;
    localparam [1:0] STATE_IDLE = 2'd0,
                     STATE_DATA = 2'd1,
                     STATE_WAIT = 2'd2;
                     
    reg [1:0] state, next_state;
    
    // 扁平化状态转换逻辑
    always @(*) begin
        next_state = state;
        if (state == STATE_IDLE && din_valid && (din == DELIMITER))
            next_state = STATE_DATA;
        else if (state == STATE_DATA)
            next_state = STATE_WAIT;
        else if (state == STATE_WAIT && !din_valid)
            next_state = STATE_IDLE;
    end
    
    // 状态寄存器更新
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) 
            state <= STATE_IDLE;
        else 
            state <= next_state;
    end
    
    // 扁平化输出逻辑
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            dout <= {DW{1'b0}};
            pkt_valid <= 1'b0;
        end
        else if (state == STATE_IDLE && din_valid && (din == DELIMITER)) begin
            dout <= din;
            pkt_valid <= 1'b1;
        end
        else if (state == STATE_WAIT && !din_valid) begin
            pkt_valid <= 1'b0;
        end
    end
endmodule