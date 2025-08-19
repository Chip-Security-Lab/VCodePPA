//SystemVerilog
// Top-level module
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
    output wire event_out
);
    // Internal signals
    wire selected_clk;
    
    // Instantiate clock multiplexer submodule
    clock_mux #(
        .NUM_SOURCES(4)
    ) u_clock_mux (
        .clk_src_0(clk_src_0),
        .clk_src_1(clk_src_1),
        .clk_src_2(clk_src_2),
        .clk_src_3(clk_src_3),
        .clk_sel(clk_sel),
        .selected_clk(selected_clk)
    );
    
    // Instantiate counter submodule
    timer_counter #(
        .COUNTER_WIDTH(COUNTER_WIDTH)
    ) u_timer_counter (
        .clk(selected_clk),
        .rst_n(rst_n),
        .threshold(threshold),
        .event_out(event_out)
    );
    
endmodule

// Clock multiplexer submodule
module clock_mux #(
    parameter NUM_SOURCES = 4
)(
    input wire clk_src_0,
    input wire clk_src_1,
    input wire clk_src_2,
    input wire clk_src_3,
    input wire [1:0] clk_sel,
    output wire selected_clk
);
    // Clock selection logic
    assign selected_clk = (clk_sel == 2'b00) ? clk_src_0 :
                         (clk_sel == 2'b01) ? clk_src_1 :
                         (clk_sel == 2'b10) ? clk_src_2 : clk_src_3;
                         
endmodule

// Timer counter submodule
module timer_counter #(
    parameter COUNTER_WIDTH = 16
)(
    input wire clk,
    input wire rst_n,
    input wire [COUNTER_WIDTH-1:0] threshold,
    output reg event_out
);
    reg [COUNTER_WIDTH-1:0] counter;
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            counter <= {COUNTER_WIDTH{1'b0}};
            event_out <= 1'b0;
        end else begin
            if (counter >= threshold - 1) begin
                counter <= {COUNTER_WIDTH{1'b0}};
                event_out <= 1'b1;
            end else begin
                counter <= counter + 1'b1;
                event_out <= 1'b0;
            end
        end
    end
    
endmodule