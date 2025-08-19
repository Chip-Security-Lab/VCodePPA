//SystemVerilog
module TimeoutArbiter #(parameter T=10) (
    input clk, rst,
    input req,
    output reg grant
);

reg [7:0] timeout;
reg [1:0] state;

localparam IDLE = 2'b00;
localparam GRANT = 2'b01;
localparam TIMEOUT = 2'b10;

wire timeout_expired = (timeout == 8'd0);
wire [7:0] next_timeout = timeout - 8'd1;

always @(posedge clk) begin
    if(rst) begin
        grant <= 1'b0;
        timeout <= 8'd0;
        state <= IDLE;
    end
    else begin
        case(state)
            IDLE: begin
                if(req) begin
                    grant <= 1'b1;
                    timeout <= T;
                    state <= GRANT;
                end
            end
            
            GRANT: begin
                if(timeout_expired) begin
                    grant <= 1'b0;
                    state <= IDLE;
                end
                else begin
                    timeout <= next_timeout;
                    state <= TIMEOUT;
                end
            end
            
            TIMEOUT: begin
                if(timeout_expired) begin
                    grant <= 1'b0;
                    state <= IDLE;
                end
                else begin
                    timeout <= next_timeout;
                end
            end
            
            default: state <= IDLE;
        endcase
    end
end

endmodule