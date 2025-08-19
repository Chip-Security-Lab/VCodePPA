//SystemVerilog
module multisource_timer #(
    parameter COUNTER_WIDTH = 16
)(
    input wire clk_src_0,
    input wire clk_src_1,
    input wire clk_src_2,
    input wire clk_src_3,
    input wire [1:0] clk_sel,
    input wire rst_n,
    input wire [COUNTER_WIDTH-1:0] threshold,
    output reg event_out
);
    reg [COUNTER_WIDTH-1:0] counter;
    wire selected_clk;
    
    // Clock enable signals for each clock source
    reg clk_en_0, clk_en_1, clk_en_2, clk_en_3;
    
    // Pipeline registers for comparison logic
    reg threshold_reached_stage1;
    reg [COUNTER_WIDTH-1:0] threshold_minus_one;
    
    // Active clock signals using enables
    wire clk0_active = clk_src_0 & clk_en_0;
    wire clk1_active = clk_src_1 & clk_en_1;
    wire clk2_active = clk_src_2 & clk_en_2;
    wire clk3_active = clk_src_3 & clk_en_3;
    
    // Create a composite clock using OR gates (safer than direct muxing)
    assign selected_clk = clk0_active | clk1_active | clk2_active | clk3_active;
    
    //-------------------- Clock Enable Logic --------------------//
    // Clock enable for clock source 0
    always @(posedge clk_src_0 or negedge rst_n) begin
        if (!rst_n) begin
            clk_en_0 <= 1'b0;
        end else begin
            clk_en_0 <= (clk_sel == 2'b00);
        end
    end
    
    // Clock enable for clock source 1
    always @(posedge clk_src_1 or negedge rst_n) begin
        if (!rst_n) begin
            clk_en_1 <= 1'b0;
        end else begin
            clk_en_1 <= (clk_sel == 2'b01);
        end
    end
    
    // Clock enable for clock source 2
    always @(posedge clk_src_2 or negedge rst_n) begin
        if (!rst_n) begin
            clk_en_2 <= 1'b0;
        end else begin
            clk_en_2 <= (clk_sel == 2'b10);
        end
    end
    
    // Clock enable for clock source 3
    always @(posedge clk_src_3 or negedge rst_n) begin
        if (!rst_n) begin
            clk_en_3 <= 1'b0;
        end else begin
            clk_en_3 <= (clk_sel == 2'b11);
        end
    end
    
    //-------------------- Threshold Calculation Logic --------------------//
    // Pipeline stage: pre-compute threshold minus one for efficient comparison
    always @(posedge selected_clk or negedge rst_n) begin
        if (!rst_n) begin
            threshold_minus_one <= {COUNTER_WIDTH{1'b0}};
        end else begin
            threshold_minus_one <= threshold - 1'b1;
        end
    end
    
    //-------------------- Threshold Comparison Logic --------------------//
    // Pipeline stage: perform comparison with counter value
    always @(posedge selected_clk or negedge rst_n) begin
        if (!rst_n) begin
            threshold_reached_stage1 <= 1'b0;
        end else begin
            threshold_reached_stage1 <= (counter >= threshold_minus_one);
        end
    end
    
    //-------------------- Counter Update Logic --------------------//
    // Update counter based on threshold comparison
    always @(posedge selected_clk or negedge rst_n) begin
        if (!rst_n) begin
            counter <= {COUNTER_WIDTH{1'b0}};
        end else begin
            counter <= threshold_reached_stage1 ? {COUNTER_WIDTH{1'b0}} : (counter + 1'b1);
        end
    end
    
    //-------------------- Output Generation Logic --------------------//
    // Generate output signal based on threshold comparison
    always @(posedge selected_clk or negedge rst_n) begin
        if (!rst_n) begin
            event_out <= 1'b0;
        end else begin
            event_out <= threshold_reached_stage1;
        end
    end
    
endmodule