module lcd_controller(
    input wire clk, rst_n,
    input wire [7:0] data_in,
    input wire start_xfer,
    output reg rs, rw, e,
    output reg [7:0] data_out,
    output reg busy
);
    localparam IDLE=3'd0, SETUP=3'd1, ENABLE=3'd2, HOLD=3'd3, DISABLE=3'd4;
    reg [2:0] state, next;
    reg [7:0] data_reg;
    reg rs_reg;
    reg [7:0] delay_cnt;
    
    always @(posedge clk or negedge rst_n)
        if (!rst_n) begin
            state <= IDLE;
            data_reg <= 8'd0;
            rs_reg <= 1'b0;
            delay_cnt <= 8'd0;
        end else begin
            state <= next;
            
            if (state == IDLE && start_xfer) begin
                data_reg <= data_in;
                rs_reg <= data_in[7]; // Command or data flag
            end
            
            if (state != next)
                delay_cnt <= 8'd0;
            else
                delay_cnt <= delay_cnt + 8'd1;
        end
    
    always @(*) begin
        busy = (state != IDLE);
        data_out = data_reg;
        rs = rs_reg;
        rw = 1'b0; // Always write mode
        e = (state == ENABLE || state == HOLD);
        
        case (state)
            IDLE: next = start_xfer ? SETUP : IDLE;
            SETUP: next = (delay_cnt >= 8'd5) ? ENABLE : SETUP;
            ENABLE: next = (delay_cnt >= 8'd10) ? HOLD : ENABLE;
            HOLD: next = (delay_cnt >= 8'd20) ? DISABLE : HOLD;
            DISABLE: next = (delay_cnt >= 8'd5) ? IDLE : DISABLE;
            default: next = IDLE;
        endcase
    end
endmodule