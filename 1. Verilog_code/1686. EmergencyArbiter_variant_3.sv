//SystemVerilog
module EmergencyArbiter (
    input clk, rst,
    input [3:0] req,
    input emergency,
    output reg [3:0] grant
);

// Buffer registers for high fanout signals
reg [3:0] req_buf;
reg [3:0] req_comp_buf;
reg [3:0] req_plus_comp_buf;
reg emergency_buf;

// First stage: Buffer input signals
always @(posedge clk) begin
    if (rst) begin
        req_buf <= 4'b0;
        emergency_buf <= 1'b0;
    end else begin
        req_buf <= req;
        emergency_buf <= emergency;
    end
end

// Second stage: Compute complement and sum
always @(posedge clk) begin
    if (rst) begin
        req_comp_buf <= 4'b0;
        req_plus_comp_buf <= 4'b0;
    end else begin
        req_comp_buf <= ~req_buf + 1'b1;
        req_plus_comp_buf <= req_buf + req_comp_buf;
    end
end

// Final stage: Generate grant
always @(posedge clk) begin
    if (rst)
        grant <= 4'b0;
    else if (emergency_buf)
        grant <= 4'b1000;
    else
        grant <= req_buf & req_plus_comp_buf;
end

endmodule