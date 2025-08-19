module QoSArbiter #(parameter QW=4) (
    input clk, rst_n,
    input [4*QW-1:0] qos, // 扁平化: 4 x QW-bit priorities
    input [3:0] req,
    output reg [3:0] grant
);
wire [QW-1:0] qos_array [0:3];
wire [QW-1:0] max_qos;
reg [QW-1:0] current_max;
integer i;

// Extract individual QoS values
genvar g;
generate
    for (g = 0; g < 4; g = g + 1) begin: qos_extract
        assign qos_array[g] = qos[g*QW +: QW];
    end
endgenerate

// Find maximum QoS
assign max_qos = (qos_array[0] > qos_array[1]) ? 
                   ((qos_array[0] > qos_array[2]) ? 
                     ((qos_array[0] > qos_array[3]) ? qos_array[0] : qos_array[3]) : 
                     ((qos_array[2] > qos_array[3]) ? qos_array[2] : qos_array[3])) : 
                   ((qos_array[1] > qos_array[2]) ? 
                     ((qos_array[1] > qos_array[3]) ? qos_array[1] : qos_array[3]) : 
                     ((qos_array[2] > qos_array[3]) ? qos_array[2] : qos_array[3]));

always @(posedge clk) begin
    if(!rst_n) grant <= 0;
    else grant <= req & (
        (qos_array[0]==max_qos) ? 4'b0001 :
        (qos_array[1]==max_qos) ? 4'b0010 :
        (qos_array[2]==max_qos) ? 4'b0100 : 4'b1000 );
end
endmodule