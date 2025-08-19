//SystemVerilog
module freq_div_square (
    input  wire        master_clk,
    input  wire        rst_b,
    input  wire [15:0] div_factor,
    output wire        clk_out
);
    
    wire       counter_overflow;
    wire [15:0] next_count;
    reg  [15:0] div_factor_reg;
    reg         overflow_reg;
    
    // 分频系数寄存器
    always @(posedge master_clk or negedge rst_b) begin
        if (!rst_b) begin
            div_factor_reg <= 16'h0000;
        end else begin
            div_factor_reg <= div_factor;
        end
    end
    
    counter_module counter_inst (
        .clk          (master_clk),
        .rst_b        (rst_b),
        .div_factor   (div_factor_reg),
        .next_count   (next_count),
        .overflow     (counter_overflow)
    );
    
    // 溢出信号寄存器
    always @(posedge master_clk or negedge rst_b) begin
        if (!rst_b) begin
            overflow_reg <= 1'b0;
        end else begin
            overflow_reg <= counter_overflow;
        end
    end
    
    clock_toggle_module toggle_inst (
        .clk          (master_clk),
        .rst_b        (rst_b),
        .toggle_en    (overflow_reg),
        .clk_out      (clk_out)
    );
    
endmodule

module counter_module (
    input  wire        clk,
    input  wire        rst_b,
    input  wire [15:0] div_factor,
    output reg  [15:0] next_count,
    output wire        overflow
);
    
    reg [15:0] count_plus_one;
    reg        overflow_pre;
    
    // 预计算下一计数值
    always @(*) begin
        count_plus_one = next_count + 16'h0001;
    end
    
    // 预计算溢出信号
    always @(*) begin
        overflow_pre = (count_plus_one >= div_factor);
    end
    
    assign overflow = overflow_pre;
    
    always @(posedge clk or negedge rst_b) begin
        if (!rst_b) begin
            next_count <= 16'h0000;
        end else begin
            if (overflow_pre) begin
                next_count <= 16'h0000;
            end else begin
                next_count <= count_plus_one;
            end
        end
    end
    
endmodule

module clock_toggle_module (
    input  wire        clk,
    input  wire        rst_b,
    input  wire        toggle_en,
    output reg         clk_out
);
    
    reg toggle_en_reg;
    
    // 使能信号寄存器
    always @(posedge clk or negedge rst_b) begin
        if (!rst_b) begin
            toggle_en_reg <= 1'b0;
        end else begin
            toggle_en_reg <= toggle_en;
        end
    end
    
    always @(posedge clk or negedge rst_b) begin
        if (!rst_b) begin
            clk_out <= 1'b0;
        end else if (toggle_en_reg) begin
            clk_out <= ~clk_out;
        end
    end
    
endmodule