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
    // Main counter registers
    reg [COUNT_WIDTH-1:0] counter;
    reg [COUNT_WIDTH-1:0] counter_next;
    
    // Split comparison logic with pipeline registers
    reg counter_is_zero;
    reg counter_is_zero_d1;
    reg timer_en_d1;
    reg [COUNT_WIDTH-1:0] reload_value_d1;
    reg intr_req_next;
    
    // Pipeline stage for zero comparison
    always @(posedge sysclk or negedge nreset) begin
        if (!nreset) begin
            counter_is_zero <= 1'b0;
            timer_en_d1 <= 1'b0;
            reload_value_d1 <= {COUNT_WIDTH{1'b0}};
        end else begin
            counter_is_zero <= (counter == {COUNT_WIDTH{1'b0}});
            timer_en_d1 <= timer_en;
            reload_value_d1 <= reload_value;
        end
    end
    
    // Further pipeline the comparison result
    always @(posedge sysclk or negedge nreset) begin
        if (!nreset) begin
            counter_is_zero_d1 <= 1'b0;
        end else begin
            counter_is_zero_d1 <= counter_is_zero;
        end
    end
    
    assign current_value = counter;
    
    // Optimized combinational logic for counter_next calculation
    always @(*) begin
        counter_next = counter;
        intr_req_next = 1'b0;
        
        if (timer_en_d1) begin
            if (counter_is_zero) begin
                counter_next = reload_value_d1;
                intr_req_next = 1'b1;
            end else begin
                counter_next = counter - 1'b1;
            end
        end
    end
    
    // Sequential logic for updating registers
    always @(posedge sysclk or negedge nreset) begin
        if (!nreset) begin
            counter <= {COUNT_WIDTH{1'b1}};
            intr_req <= 1'b0;
        end else begin
            counter <= counter_next;
            intr_req <= intr_req_next;
        end
    end
endmodule