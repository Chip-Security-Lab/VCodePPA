//SystemVerilog
module ErrorCounter #(parameter WIDTH=8, MAX_ERR=3) (
    input clk, rst_n,
    input [WIDTH-1:0] data,
    input [WIDTH-1:0] pattern,
    output reg alarm
);
    // 使用宽度自适应的错误计数器，只需要能计数到MAX_ERR+1
    localparam ERR_CNT_WIDTH = $clog2(MAX_ERR+2);  
    reg [ERR_CNT_WIDTH-1:0] err_count;
    
    // 使用更高效的比较逻辑
    wire data_mismatch;
    assign data_mismatch = (data != pattern);

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            err_count <= 0;
            alarm <= 0;
        end else begin
            // 避免不必要的加法，使用直接赋值条件
            if (data_mismatch) begin
                // 只有在未达到最大值时才增加计数器
                if (err_count < {ERR_CNT_WIDTH{1'b1}})
                    err_count <= err_count + 1'b1;
            end else begin
                err_count <= 0;
            end
            
            // 使用非阻塞赋值并将报警逻辑与计数分离，优化时序
            alarm <= (err_count >= MAX_ERR - 1'b1) && data_mismatch;
        end
    end
endmodule