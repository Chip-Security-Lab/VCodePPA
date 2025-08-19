//SystemVerilog
module QoSArbiter #(parameter QW=4) (
    input clk, rst_n,
    input [4*QW-1:0] qos,
    input [3:0] req,
    output reg [3:0] grant
);

wire [QW-1:0] qos_array [0:3];
reg [QW-1:0] max_qos;
reg [1:0] max_idx;

genvar g;
generate
    for (g = 0; g < 4; g = g + 1) begin: qos_extract
        assign qos_array[g] = qos[g*QW +: QW];
    end
endgenerate

always @(*) begin
    max_qos = qos_array[0];
    max_idx = 2'd0;
    
    if (qos_array[1] > max_qos) begin
        max_qos = qos_array[1];
        max_idx = 2'd1;
    end
    
    if (qos_array[2] > max_qos) begin
        max_qos = qos_array[2];
        max_idx = 2'd2;
    end
    
    if (qos_array[3] > max_qos) begin
        max_qos = qos_array[3];
        max_idx = 2'd3;
    end
end

always @(posedge clk) begin
    if (!rst_n) begin
        grant <= 4'b0000;
    end else begin
        if (max_idx == 2'd0) begin
            grant <= req & 4'b0001;
        end else if (max_idx == 2'd1) begin
            grant <= req & 4'b0010;
        end else if (max_idx == 2'd2) begin
            grant <= req & 4'b0100;
        end else if (max_idx == 2'd3) begin
            grant <= req & 4'b1000;
        end else begin
            grant <= 4'b0000;
        end
    end
end

endmodule