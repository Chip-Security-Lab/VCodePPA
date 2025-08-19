//SystemVerilog
module shadow_reg_fsm #(parameter DW=8) (
    input clk, rst, trigger,
    input [DW-1:0] data_in,
    output reg [DW-1:0] data_out
);
    // 改用参数化的状态编码
    localparam IDLE = 1'b0;
    localparam LOAD = 1'b1;
    
    reg [DW-1:0] shadow;
    reg state;
    
    always @(posedge clk) begin
        if(rst) begin
            state <= IDLE;
            shadow <= {DW{1'b0}};
            data_out <= {DW{1'b0}};
        end
        else begin
            case(state)
                IDLE: begin
                    if(trigger) begin
                        shadow <= data_in;
                        state <= LOAD;
                    end
                end
                LOAD: begin
                    data_out <= shadow;
                    state <= IDLE;
                end
            endcase
        end
    end
endmodule