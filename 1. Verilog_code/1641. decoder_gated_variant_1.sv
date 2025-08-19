//SystemVerilog
module decoder_gated #(WIDTH=3) (
    input clk,
    input valid,
    output ready,
    input [WIDTH-1:0] addr,
    output [7:0] decoded
);

wire [7:0] decoded_raw;
reg ready_reg;
reg [7:0] decoded_reg;

// 地址解码子模块
decoder_core #(WIDTH) u_decoder_core (
    .addr(addr),
    .decoded_raw(decoded_raw)
);

// 时钟使能控制子模块
decoder_control u_decoder_control (
    .clk(clk),
    .valid(valid),
    .ready(ready_reg),
    .decoded_raw(decoded_raw),
    .decoded(decoded_reg)
);

assign ready = ready_reg;
assign decoded = decoded_reg;

endmodule

module decoder_core #(WIDTH=3) (
    input [WIDTH-1:0] addr,
    output reg [7:0] decoded_raw
);

always @(*) begin
    decoded_raw = 1 << addr;
end

endmodule

module decoder_control (
    input clk,
    input valid,
    output reg ready,
    input [7:0] decoded_raw,
    output reg [7:0] decoded
);

reg [1:0] state;
localparam IDLE = 2'b00;
localparam PROCESS = 2'b01;
localparam DONE = 2'b10;

always @(posedge clk) begin
    case(state)
        IDLE: begin
            if(valid) begin
                state <= PROCESS;
                ready <= 1'b0;
            end
            else begin
                ready <= 1'b1;
            end
        end
        PROCESS: begin
            decoded <= decoded_raw;
            state <= DONE;
        end
        DONE: begin
            if(!valid) begin
                state <= IDLE;
                ready <= 1'b1;
            end
        end
    endcase
end

endmodule