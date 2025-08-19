//SystemVerilog
module crossbar_bidir #(parameter DATA_WIDTH=8, parameter PORTS=4) (
    inout [PORTS*DATA_WIDTH-1:0] port, // 打平的数组
    input [PORTS*PORTS-1:0] connect_map // 打平的连接映射
);
    genvar i, j;
    wire [DATA_WIDTH-1:0] tri_state;
    assign tri_state = {DATA_WIDTH{1'bz}}; // 高阻态
    reg [PORTS-1:0] connect_map_2d [0:PORTS-1];
    integer k, l;

    // 将一维数组转为二维
    always @(*) begin
        for(k=0; k<PORTS; k=k+1) begin
            for(l=0; l<PORTS; l=l+1) begin
                connect_map_2d[k][l] = connect_map[k*PORTS+l];
            end
        end
    end

    generate
        for(i=0; i<PORTS; i=i+1) begin: gen_port
            for(j=0; j<PORTS; j=j+1) begin: gen_conn
                // 使用条件运算符替代if-else结构
                wire [DATA_WIDTH-1:0] conn_data;
                assign conn_data = connect_map_2d[j][i] ? port[(j*DATA_WIDTH) +: DATA_WIDTH] : tri_state;
                assign port[(i*DATA_WIDTH) +: DATA_WIDTH] = conn_data;
            end
        end
    endgenerate
endmodule