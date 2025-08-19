//SystemVerilog
module async_combo_timer #(parameter CNT_WIDTH = 16)(
    input wire clock, reset, timer_en,
    input wire [CNT_WIDTH-1:0] max_count,
    output wire [CNT_WIDTH-1:0] counter_val,
    output wire timer_done
);
    // Internal connections between sub-modules
    wire equal_flag;
    
    // Instantiate equality detector sub-module
    equality_detector #(
        .WIDTH(CNT_WIDTH)
    ) u_equality_detector (
        .clock(clock),
        .reset(reset),
        .value_a(counter_val),
        .value_b(max_count),
        .equal_flag(equal_flag)
    );
    
    // Instantiate counter sub-module
    counter_module #(
        .CNT_WIDTH(CNT_WIDTH)
    ) u_counter (
        .clock(clock),
        .reset(reset),
        .enable(timer_en),
        .clear(equal_flag),
        .counter_val(counter_val)
    );
    
    // Instantiate timer status module
    timer_status_module u_timer_status (
        .clock(clock),
        .reset(reset),
        .timer_en(timer_en),
        .equal_flag(equal_flag),
        .timer_done(timer_done)
    );
    
endmodule

// Sub-module for detecting equality between two values
module equality_detector #(parameter WIDTH = 16)(
    input wire clock,
    input wire reset,
    input wire [WIDTH-1:0] value_a,
    input wire [WIDTH-1:0] value_b,
    output reg equal_flag
);
    // Registered equality comparison
    always @(posedge clock) begin
        if (reset)
            equal_flag <= 1'b0;
        else
            equal_flag <= (value_a == value_b);
    end
endmodule

// Sub-module for counter functionality
module counter_module #(parameter CNT_WIDTH = 16)(
    input wire clock,
    input wire reset,
    input wire enable,
    input wire clear,
    output wire [CNT_WIDTH-1:0] counter_val
);
    reg [CNT_WIDTH-1:0] cnt_reg;
    
    // Counter logic
    always @(posedge clock) begin
        if (reset)
            cnt_reg <= {CNT_WIDTH{1'b0}};
        else if (enable)
            cnt_reg <= clear ? {CNT_WIDTH{1'b0}} : cnt_reg + 1'b1;
    end
    
    assign counter_val = cnt_reg;
endmodule

// Sub-module for timer status management
module timer_status_module (
    input wire clock,
    input wire reset,
    input wire timer_en,
    input wire equal_flag,
    output wire timer_done
);
    reg timer_done_reg;
    
    // Timer status logic
    always @(posedge clock) begin
        if (reset)
            timer_done_reg <= 1'b0;
        else
            timer_done_reg <= equal_flag && timer_en;
    end
    
    assign timer_done = timer_done_reg;
endmodule