//SystemVerilog
module timestamp_capture #(
    parameter TIMESTAMP_WIDTH = 32
)(
    input wire clk,
    input wire rst,
    input wire [3:0] event_triggers,
    output reg [3:0] event_detected,
    output reg [TIMESTAMP_WIDTH-1:0] timestamps [0:3]
);
    reg [TIMESTAMP_WIDTH-1:0] free_running_counter;
    reg [3:0] event_triggers_reg;
    wire [3:0] rising_edges;
    
    // 将输入信号寄存，减少输入到第一级寄存器的延迟
    always @(posedge clk) begin
        if (rst) begin
            event_triggers_reg <= 4'b0000;
        end else begin
            event_triggers_reg <= event_triggers;
        end
    end
    
    // 使用寄存后的信号计算上升沿
    assign rising_edges = event_triggers_reg & ~event_triggers_reg_delayed;
    
    reg [3:0] event_triggers_reg_delayed;
    
    integer i;
    
    always @(posedge clk) begin
        if (rst) begin
            free_running_counter <= {TIMESTAMP_WIDTH{1'b0}};
            event_detected <= 4'b0000;
            event_triggers_reg_delayed <= 4'b0000;
            
            // Initialize timestamps array
            for (i = 0; i < 4; i = i + 1) begin
                timestamps[i] <= {TIMESTAMP_WIDTH{1'b0}};
            end
        end else begin
            free_running_counter <= free_running_counter + 1'b1;
            event_triggers_reg_delayed <= event_triggers_reg;
            
            // Timestamp capture using the rising edges signal
            for (i = 0; i < 4; i = i + 1) begin
                if (rising_edges[i]) begin
                    timestamps[i] <= free_running_counter;
                    event_detected[i] <= 1'b1;
                end
            end
        end
    end
endmodule