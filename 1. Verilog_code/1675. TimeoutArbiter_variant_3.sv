//SystemVerilog
// Timeout Counter Submodule
module TimeoutCounter #(parameter T=10) (
    input clk,
    input rst,
    input enable,
    output reg [7:0] timeout
);

reg [7:0] lut_sub[0:255];

// Initialize LUT for subtraction
initial begin
    for (int i = 0; i < 256; i = i + 1) begin
        lut_sub[i] = (i == 0) ? 8'hFF : (i - 1);
    end
end

always @(posedge clk) begin
    if (rst) begin
        timeout <= 0;
    end else if (enable) begin
        if (timeout == 0) begin
            timeout <= T;
        end else begin
            timeout <= lut_sub[timeout];
        end
    end
end

endmodule

// Grant Control Submodule
module GrantControl (
    input clk,
    input rst,
    input req,
    input timeout_zero,
    output reg grant
);

always @(posedge clk) begin
    if (rst) begin
        grant <= 0;
    end else if (timeout_zero) begin
        grant <= req;
    end
end

endmodule

// Top-level TimeoutArbiter Module
module TimeoutArbiter #(parameter T=10) (
    input clk,
    input rst,
    input req,
    output grant
);

wire [7:0] timeout;
wire timeout_zero = (timeout == 0);

TimeoutCounter #(.T(T)) counter_inst (
    .clk(clk),
    .rst(rst),
    .enable(1'b1),
    .timeout(timeout)
);

GrantControl grant_inst (
    .clk(clk),
    .rst(rst),
    .req(req),
    .timeout_zero(timeout_zero),
    .grant(grant)
);

endmodule