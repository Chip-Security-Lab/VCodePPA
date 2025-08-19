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
    // Stage 1: Counter management and calculation
    reg [COUNT_WIDTH-1:0] counter_stage1;
    reg [COUNT_WIDTH-1:0] counter_next;
    reg counter_zero_stage1;
    reg valid_stage1;
    reg timer_en_stage1;
    
    // Stage 2: Interrupt generation and state handling
    reg [COUNT_WIDTH-1:0] counter_stage2;
    reg counter_zero_stage2;
    reg valid_stage2;
    reg timer_en_stage2;
    
    // Output connection
    assign current_value = counter_stage2;
    
    // Stage 1: Counter calculation logic
    always @(posedge sysclk or negedge nreset) begin
        if (!nreset) begin
            counter_stage1 <= {COUNT_WIDTH{1'b1}};
            counter_zero_stage1 <= 1'b0;
            valid_stage1 <= 1'b0;
            timer_en_stage1 <= 1'b0;
        end
        else begin
            valid_stage1 <= 1'b1;
            timer_en_stage1 <= timer_en;
            
            // Detect zero condition
            counter_zero_stage1 <= (counter_stage1 == {COUNT_WIDTH{1'b0}});
            
            // Calculate next counter value
            if (timer_en) begin
                if (counter_stage1 == {COUNT_WIDTH{1'b0}}) begin
                    counter_stage1 <= reload_value;
                end
                else begin
                    counter_stage1 <= counter_stage1 - 1'b1;
                end
            end
        end
    end
    
    // Stage 2: Interrupt generation
    always @(posedge sysclk or negedge nreset) begin
        if (!nreset) begin
            counter_stage2 <= {COUNT_WIDTH{1'b1}};
            counter_zero_stage2 <= 1'b0;
            valid_stage2 <= 1'b0;
            timer_en_stage2 <= 1'b0;
            intr_req <= 1'b0;
        end
        else begin
            // Forward pipeline signals
            counter_stage2 <= counter_stage1;
            counter_zero_stage2 <= counter_zero_stage1;
            valid_stage2 <= valid_stage1;
            timer_en_stage2 <= timer_en_stage1;
            
            // Generate interrupt based on pipeline state
            if (valid_stage2 && timer_en_stage2 && counter_zero_stage2) begin
                intr_req <= 1'b1;
            end
            else begin
                intr_req <= 1'b0;
            end
        end
    end
endmodule