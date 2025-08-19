//SystemVerilog
module cascade_parity (
    input clk,
    input rst_n,
    input req,
    output reg ack,
    input [7:0] data,
    output reg parity
);

reg [3:0] nib_par;
reg [7:0] data_reg;
reg req_reg;
reg [1:0] state;

localparam IDLE = 2'b00;
localparam CALC = 2'b01;
localparam WAIT = 2'b10;

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        ack <= 1'b0;
        parity <= 1'b0;
        data_reg <= 8'b0;
        req_reg <= 1'b0;
        state <= IDLE;
    end else begin
        req_reg <= req;
        case (state)
            IDLE: begin
                if (req && !req_reg) begin
                    data_reg <= data;
                    nib_par[0] <= ^data[3:0];
                    nib_par[1] <= ^data[7:4];
                    parity <= ^nib_par;
                    ack <= 1'b1;
                    state <= CALC;
                end
            end
            CALC: begin
                if (!req) begin
                    ack <= 1'b0;
                    state <= IDLE;
                end
            end
            default: state <= IDLE;
        endcase
    end
end

endmodule