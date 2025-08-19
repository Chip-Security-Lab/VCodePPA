module cam_restart #(parameter WIDTH=10, DEPTH=32)(
    input clk,
    input restart,
    input write_en,                      // 添加写入使能
    input [$clog2(DEPTH)-1:0] write_addr, // 添加写入地址
    input [WIDTH-1:0] write_data,        // 添加写入数据
    input [WIDTH-1:0] data_in,
    output reg [DEPTH-1:0] partial_matches
);
    reg [2:0] compare_phase;
    reg [WIDTH-1:0] cam_entry [0:DEPTH-1]; // 添加缺失的数组声明
    
    // 添加写入逻辑
    always @(posedge clk) begin
        if (write_en)
            cam_entry[write_addr] <= write_data;
    end
    
    // 修正比较逻辑
    integer i;
    always @(posedge clk) begin
        if(restart) begin
            compare_phase <= 0;
            partial_matches <= {DEPTH{1'b1}};
        end else begin
            compare_phase <= compare_phase + 1;
            for(i=0; i<DEPTH; i=i+1) begin
                // 修正部分选择，使用固定位选择而非动态索引
                case(compare_phase)
                    3'd0: partial_matches[i] <= partial_matches[i] & (data_in[2:0] == cam_entry[i][2:0]);
                    3'd1: partial_matches[i] <= partial_matches[i] & (data_in[5:3] == cam_entry[i][5:3]);
                    3'd2: partial_matches[i] <= partial_matches[i] & (data_in[8:6] == cam_entry[i][8:6]);
                    default: partial_matches[i] <= partial_matches[i];
                endcase
            end
        end
    end
endmodule