module one_wire_codec (
    input clk, rst,
    inout dq,
    output reg [7:0] romcode
);
    reg [2:0] state;
    reg precharge;
    
    always @(negedge clk) begin
        if (rst) begin
            state <= 3'd0;
            precharge <= 1'b0;
            romcode <= 8'd0;
        end else begin
            case(state)
                3'd0: if(!dq) begin // Detect reset pulse
                    precharge <= 1'b1;
                    state <= 3'd1;
                end
                3'd1: begin
                    precharge <= 1'b0; // Release the bus
                    if(dq) begin
                        state <= 3'd2;
                        romcode <= 8'd0;
                    end
                end
                3'd2: begin // ROM读取第一位
                    romcode[0] <= dq;
                    state <= 3'd3;
                end
                3'd3: begin // ROM读取第二位
                    romcode[1] <= dq;
                    state <= 3'd4;
                end
                3'd4: begin // ROM读取第三位
                    romcode[2] <= dq;
                    state <= 3'd5;
                end
                3'd5: begin // ROM读取第四位
                    romcode[3] <= dq;
                    state <= 3'd6;
                end
                3'd6: begin // ROM读取第五位
                    romcode[4] <= dq;
                    state <= 3'd7;
                end
                3'd7: begin // ROM读取最后三位
                    romcode[5] <= dq;
                    state <= 3'd0;
                end
                default: state <= 3'd0;
            endcase
        end
    end
    
    assign dq = precharge ? 1'b0 : 1'bz;
endmodule