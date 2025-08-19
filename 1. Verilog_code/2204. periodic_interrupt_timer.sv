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
    
    assign current_value = counter;
    
    always @(posedge sysclk or negedge nreset) begin
        if (!nreset) begin
            counter <= {COUNT_WIDTH{1'b1}};
            intr_req <= 1'b0;
        end else if (timer_en) begin
            if (counter == {COUNT_WIDTH{1'b0}}) begin
                counter <= reload_value;
                intr_req <= 1'b1;
            end else begin
                counter <= counter - 1'b1;
                intr_req <= 1'b0;
            end
        end else begin
            intr_req <= 1'b0;
        end
    end
endmodule