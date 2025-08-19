//SystemVerilog
module PriorityRecovery #(parameter WIDTH=8, SOURCES=4) (
    input wire clk,
    input wire rst_n,
    input wire [SOURCES-1:0] valid,
    input wire [WIDTH*SOURCES-1:0] data_bus,
    input wire input_ready,
    output wire output_valid,
    output wire [WIDTH-1:0] selected_data
);
    // 流水线阶段1：检测最高优先级
    reg [1:0] priority_stage1;
    reg valid_stage1;
    reg [WIDTH*SOURCES-1:0] data_bus_stage1;
    
    // 高扇出信号缓冲
    reg [SOURCES-1:0] valid_buf1, valid_buf2;
    reg [WIDTH*SOURCES-1:0] data_bus_buf1, data_bus_buf2;
    
    // 流水线阶段2：根据优先级选择数据
    reg [WIDTH-1:0] selected_data_stage2;
    reg valid_stage2;
    
    // 输入信号缓冲 - 减少高扇出信号的负载
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            valid_buf1 <= {SOURCES{1'b0}};
            valid_buf2 <= {SOURCES{1'b0}};
            data_bus_buf1 <= {(WIDTH*SOURCES){1'b0}};
            data_bus_buf2 <= {(WIDTH*SOURCES){1'b0}};
        end else if (input_ready) begin
            valid_buf1 <= valid;
            valid_buf2 <= valid;
            data_bus_buf1 <= data_bus;
            data_bus_buf2 <= data_bus;
        end
    end
    
    // 第一级流水线 - 优先级检测
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            priority_stage1 <= 2'b00;
            valid_stage1 <= 1'b0;
            data_bus_stage1 <= {(WIDTH*SOURCES){1'b0}};
        end else if (input_ready) begin
            data_bus_stage1 <= data_bus_buf1;
            valid_stage1 <= |valid_buf1;
            
            // 使用普通case和条件判断替代casex
            case (1'b1)
                valid_buf1[3]: priority_stage1 <= 2'b11; // 优先级3
                valid_buf1[2]: priority_stage1 <= 2'b10; // 优先级2
                valid_buf1[1]: priority_stage1 <= 2'b01; // 优先级1
                valid_buf1[0]: priority_stage1 <= 2'b00; // 优先级0
                default:       priority_stage1 <= 2'b00;
            endcase
        end
    end
    
    // 数据分块缓冲 - 为数据总线不同部分创建专用缓冲
    reg [WIDTH-1:0] data_slice0, data_slice1, data_slice2, data_slice3;
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            data_slice0 <= {WIDTH{1'b0}};
            data_slice1 <= {WIDTH{1'b0}};
            data_slice2 <= {WIDTH{1'b0}};
            data_slice3 <= {WIDTH{1'b0}};
        end else begin
            data_slice0 <= data_bus_stage1[WIDTH*0 +: WIDTH];
            data_slice1 <= data_bus_stage1[WIDTH*1 +: WIDTH];
            data_slice2 <= data_bus_stage1[WIDTH*2 +: WIDTH];
            data_slice3 <= data_bus_stage1[WIDTH*3 +: WIDTH];
        end
    end
    
    // 第二级流水线 - 数据选择
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            selected_data_stage2 <= {WIDTH{1'b0}};
            valid_stage2 <= 1'b0;
        end else begin
            valid_stage2 <= valid_stage1;
            
            case (priority_stage1)
                2'b11: selected_data_stage2 <= data_slice3;
                2'b10: selected_data_stage2 <= data_slice2;
                2'b01: selected_data_stage2 <= data_slice1;
                2'b00: selected_data_stage2 <= data_slice0;
                default: selected_data_stage2 <= {WIDTH{1'b0}};
            endcase
        end
    end
    
    // 输出赋值
    assign selected_data = selected_data_stage2;
    assign output_valid = valid_stage2;
    
endmodule