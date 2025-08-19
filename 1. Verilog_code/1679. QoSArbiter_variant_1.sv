//SystemVerilog
module QoSArbiter #(parameter QW=4) (
    input clk, rst_n,
    input [4*QW-1:0] qos,
    input [3:0] req,
    output reg [3:0] grant
);

wire [QW-1:0] qos_array [0:3];
wire [QW-1:0] max_qos_stage1 [0:1];
reg [QW-1:0] max_qos_stage2;
reg [QW-1:0] max_qos_stage3;
reg [QW-1:0] current_max;
reg [3:0] grant_stage1;
integer i;

// Extract individual QoS values
genvar g;
generate
    for (g = 0; g < 4; g = g + 1) begin: qos_extract
        assign qos_array[g] = qos[g*QW +: QW];
    end
endgenerate

// First stage of max comparison
assign max_qos_stage1[0] = (qos_array[0] > qos_array[1]) ? qos_array[0] : qos_array[1];
assign max_qos_stage1[1] = (qos_array[2] > qos_array[3]) ? qos_array[2] : qos_array[3];

// Second stage of max comparison
always @(posedge clk) begin
    if (!rst_n) begin
        max_qos_stage2 <= 0;
    end else begin
        max_qos_stage2 <= (max_qos_stage1[0] > max_qos_stage1[1]) ? max_qos_stage1[0] : max_qos_stage1[1];
    end
end

// Third stage of max comparison
always @(posedge clk) begin
    if (!rst_n) begin
        max_qos_stage3 <= 0;
    end else begin
        max_qos_stage3 <= max_qos_stage2;
    end
end

// Grant generation stage 1
always @(posedge clk) begin
    if (!rst_n) begin
        grant_stage1 <= 0;
    end else begin
        grant_stage1 <= req & (
            (qos_array[0] == max_qos_stage2) ? 4'b0001 :
            (qos_array[1] == max_qos_stage2) ? 4'b0010 :
            (qos_array[2] == max_qos_stage2) ? 4'b0100 : 4'b1000
        );
    end
end

// Final grant output stage
always @(posedge clk) begin
    if (!rst_n) begin
        grant <= 0;
    end else begin
        grant <= grant_stage1;
    end
end

endmodule