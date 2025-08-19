//SystemVerilog
// 顶层模块
module int_ctrl_sync_fixed #(
    parameter WIDTH = 8
)(
    input clk, rst_n, en,
    input [WIDTH-1:0] req,
    output [$clog2(WIDTH)-1:0] grant
);
    // 内部连线
    wire [$clog2(WIDTH)-1:0] priority_encoder_out;
    wire priority_valid;
    
    // 优先级编码器子模块实例化
    priority_encoder #(
        .WIDTH(WIDTH)
    ) priority_encoder_inst (
        .req(req),
        .encoded_out(priority_encoder_out),
        .valid(priority_valid)
    );
    
    // 输出寄存器子模块实例化
    output_register #(
        .WIDTH(WIDTH)
    ) output_register_inst (
        .clk(clk),
        .rst_n(rst_n),
        .en(en),
        .priority_valid(priority_valid),
        .priority_encoder_out(priority_encoder_out),
        .grant(grant)
    );
endmodule

// 优先级编码器子模块
module priority_encoder #(
    parameter WIDTH = 8
)(
    input [WIDTH-1:0] req,
    output reg [$clog2(WIDTH)-1:0] encoded_out,
    output reg valid
);
    integer i;
    
    // 组合逻辑处理优先级编码
    always @(*) begin
        encoded_out = {$clog2(WIDTH){1'b0}};
        valid = 1'b0;
        
        for(i = WIDTH-1; i >= 0; i = i - 1) begin
            if(req[i]) begin
                encoded_out = i[$clog2(WIDTH)-1:0];
                valid = 1'b1;
            end
        end
    end
endmodule

// 输出寄存器子模块
module output_register #(
    parameter WIDTH = 8
)(
    input clk, rst_n, en,
    input priority_valid,
    input [$clog2(WIDTH)-1:0] priority_encoder_out,
    output reg [$clog2(WIDTH)-1:0] grant
);
    // 时序逻辑处理输出寄存器
    always @(posedge clk or negedge rst_n) begin
        if(!rst_n) begin
            grant <= {$clog2(WIDTH){1'b0}};
        end
        else if(en) begin
            if(priority_valid)
                grant <= priority_encoder_out;
            else
                grant <= {$clog2(WIDTH){1'b0}};
        end
    end
endmodule