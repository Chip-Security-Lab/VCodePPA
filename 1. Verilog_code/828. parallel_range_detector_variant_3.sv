//SystemVerilog
// Top-level module
module parallel_range_detector(
    input wire clk, rst_n,
    input wire [15:0] data_val,
    input wire [15:0] range_start, range_end,
    output wire lower_than_range,
    output wire inside_range,
    output wire higher_than_range
);

    // Pipeline stage 1: Range width calculation
    reg [15:0] range_width_reg;
    wire [15:0] range_width = range_end - range_start;
    
    // Pipeline stage 2: Offset calculation
    reg [15:0] offset_val_reg;
    wire [15:0] offset_val = data_val - range_start;
    
    // Pipeline stage 3: Range detection
    reg lower_than_range_reg;
    reg inside_range_reg;
    reg higher_than_range_reg;
    
    // Pipeline stage 1
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            range_width_reg <= 16'd0;
        end else begin
            range_width_reg <= range_width;
        end
    end
    
    // Pipeline stage 2
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            offset_val_reg <= 16'd0;
        end else begin
            offset_val_reg <= offset_val;
        end
    end
    
    // Pipeline stage 3
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            lower_than_range_reg <= 1'b0;
            inside_range_reg <= 1'b0;
            higher_than_range_reg <= 1'b0;
        end else begin
            lower_than_range_reg <= offset_val_reg[15];
            inside_range_reg <= ~offset_val_reg[15] && (offset_val_reg <= range_width_reg);
            higher_than_range_reg <= ~offset_val_reg[15] && (offset_val_reg > range_width_reg);
        end
    end
    
    // Output assignments
    assign lower_than_range = lower_than_range_reg;
    assign inside_range = inside_range_reg;
    assign higher_than_range = higher_than_range_reg;

endmodule