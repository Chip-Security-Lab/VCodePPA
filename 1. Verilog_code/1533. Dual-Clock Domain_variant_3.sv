//SystemVerilog
// IEEE 1364-2005
module dual_clk_shadow_reg #(
    parameter WIDTH = 8
)(
    // Primary domain
    input wire clk_pri,
    input wire rst_n_pri,
    input wire [WIDTH-1:0] data_pri,
    input wire capture,
    
    // Shadow domain
    input wire clk_shd,
    input wire rst_n_shd,
    output wire [WIDTH-1:0] shadow_data
);
    // Internal connections
    wire cap_flag_to_sync;
    wire cap_sync_to_pri;
    wire cap_detect_to_control;
    wire [WIDTH-1:0] pri_reg_to_shadow;
    
    // Primary domain module
    primary_domain #(
        .WIDTH(WIDTH)
    ) pri_domain_inst (
        .clk(clk_pri),
        .rst_n(rst_n_pri),
        .data_in(data_pri),
        .capture(capture),
        .cap_sync(cap_sync_to_pri),
        .pri_reg_out(pri_reg_to_shadow),
        .cap_flag(cap_flag_to_sync)
    );
    
    // Clock domain crossing module
    cdc_synchronizer cdc_sync_inst (
        .clk_dst(clk_shd),
        .rst_n_dst(rst_n_shd),
        .signal_src(cap_flag_to_sync),
        .signal_meta(),
        .signal_dst(cap_detect_to_control)
    );
    
    // Shadow domain control and data handling
    shadow_domain #(
        .WIDTH(WIDTH)
    ) shd_domain_inst (
        .clk(clk_shd),
        .rst_n(rst_n_shd),
        .pri_reg(pri_reg_to_shadow),
        .cap_detect(cap_detect_to_control),
        .cap_sync(cap_sync_to_pri),
        .shadow_data(shadow_data)
    );
    
endmodule

// Primary domain logic
module primary_domain #(
    parameter WIDTH = 8
)(
    input wire clk,
    input wire rst_n,
    input wire [WIDTH-1:0] data_in,
    input wire capture,
    input wire cap_sync,
    output reg [WIDTH-1:0] pri_reg_out,
    output reg cap_flag
);
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            pri_reg_out <= {WIDTH{1'b0}};
            cap_flag <= 1'b0;
        end else begin
            pri_reg_out <= data_in;
            cap_flag <= capture ? 1'b1 : (cap_sync ? 1'b0 : cap_flag);
        end
    end
    
endmodule

// Clock domain crossing synchronizer
module cdc_synchronizer (
    input wire clk_dst,
    input wire rst_n_dst,
    input wire signal_src,
    output reg signal_meta,
    output reg signal_dst
);
    
    always @(posedge clk_dst or negedge rst_n_dst) begin
        if (!rst_n_dst) begin
            signal_meta <= 1'b0;
            signal_dst <= 1'b0;
        end else begin
            signal_meta <= signal_src;
            signal_dst <= signal_meta;
        end
    end
    
endmodule

// Shadow domain logic with borrow subtractor
module shadow_domain #(
    parameter WIDTH = 8
)(
    input wire clk,
    input wire rst_n,
    input wire [WIDTH-1:0] pri_reg,
    input wire cap_detect,
    output reg cap_sync,
    output reg [WIDTH-1:0] shadow_data
);
    
    reg [WIDTH-1:0] borrow;
    reg [WIDTH-1:0] subtrahend;
    wire cap_edge_detect;
    
    // Edge detection for capture signal
    assign cap_edge_detect = cap_detect && !cap_sync;
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            cap_sync <= 1'b0;
            shadow_data <= {WIDTH{1'b0}};
            subtrahend <= {WIDTH{1'b0}};
            borrow <= {WIDTH{1'b0}};
        end else begin
            if (cap_edge_detect) begin
                // Implement borrow subtractor algorithm
                subtrahend <= ~pri_reg + 1'b1; // 2's complement
                borrow[0] <= (1'b0 < pri_reg[0]) ? 1'b1 : 1'b0;
                
                // Borrow calculation
                borrow_calculation(pri_reg, borrow);
                
                // Update shadow_data and set capture sync flag
                shadow_data <= pri_reg;
                cap_sync <= 1'b1;
            end else if (!cap_detect) begin
                cap_sync <= 1'b0;
            end
        end
    end
    
    // Task for borrow calculation to improve readability
    task borrow_calculation;
        input [WIDTH-1:0] operand;
        output [WIDTH-1:0] borrow_out;
        integer i;
    begin
        borrow_out[0] = (1'b0 < operand[0]) ? 1'b1 : 1'b0;
        for (i = 1; i < WIDTH; i = i + 1) begin
            borrow_out[i] = ((1'b0 < operand[i]) || ((1'b0 == operand[i]) && borrow_out[i-1])) ? 1'b1 : 1'b0;
        end
    end
    endtask
    
endmodule