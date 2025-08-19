//SystemVerilog
module periodic_interrupt_timer #(
    parameter COUNT_WIDTH = 24
)(
    input wire sysclk,
    input wire nreset,
    input wire [COUNT_WIDTH-1:0] reload_value,
    input wire timer_en,
    output reg intr_req,
    output wire [COUNT_WIDTH-1:0] current_value
);
    reg [COUNT_WIDTH-1:0] counter;
    wire [COUNT_WIDTH-1:0] counter_next;
    wire [COUNT_WIDTH-1:0] ones_complement;
    
    assign current_value = counter;
    
    // 使用补码加法实现减法: counter - 1 = counter + (~1 + 1) = counter + 'hFFFFFF
    assign ones_complement = {COUNT_WIDTH{1'b1}}; // 全1，相当于~0
    assign counter_next = counter + ones_complement;
    
    always @(posedge sysclk or negedge nreset) begin
        if (!nreset) begin
            counter <= {COUNT_WIDTH{1'b1}};
            intr_req <= 1'b0;
        end else if (timer_en) begin
            if (counter == {COUNT_WIDTH{1'b0}}) begin
                counter <= reload_value;
                intr_req <= 1'b1;
            end else begin
                counter <= counter_next;
                intr_req <= 1'b0;
            end
        end else begin
            intr_req <= 1'b0;
        end
    end
endmodule