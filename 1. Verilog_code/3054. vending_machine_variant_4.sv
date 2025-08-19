//SystemVerilog
module vending_machine_axi_stream(
    input wire aclk,
    input wire aresetn,
    
    // AXI-Stream Slave Interface
    input wire s_axis_tvalid,
    output reg s_axis_tready,
    input wire [1:0] s_axis_tdata,
    input wire s_axis_tlast,
    
    // AXI-Stream Master Interface
    output reg m_axis_tvalid,
    input wire m_axis_tready,
    output reg [0:0] m_axis_tdata,
    output reg m_axis_tlast
);
    
    reg [4:0] state, next_state;
    reg [1:0] coin_reg;
    reg dispense_reg;
    
    // Booth multiplier signals
    reg [4:0] booth_result;
    reg [4:0] booth_state;
    reg [4:0] booth_next_state;
    reg [4:0] booth_accumulator;
    reg [4:0] booth_multiplier;
    reg [4:0] booth_multiplicand;
    reg booth_done;
    reg booth_start;
    
    // State machine
    always @(posedge aclk or negedge aresetn)
        if (!aresetn) begin
            state <= 5'd0;
            coin_reg <= 2'b0;
            dispense_reg <= 1'b0;
            booth_state <= 5'd0;
            booth_accumulator <= 5'd0;
            booth_multiplier <= 5'd0;
            booth_multiplicand <= 5'd0;
            booth_done <= 1'b0;
            booth_start <= 1'b0;
        end else begin
            if (s_axis_tvalid && s_axis_tready) begin
                coin_reg <= s_axis_tdata;
                state <= next_state;
                
                // Initialize Booth multiplication when state changes
                booth_start <= 1'b1;
                booth_multiplier <= state;
                booth_multiplicand <= 5'd1;
            end else begin
                booth_start <= 1'b0;
            end
            
            if (m_axis_tvalid && m_axis_tready) begin
                dispense_reg <= 1'b0;
            end
            
            // Booth multiplication state machine
            if (booth_start) begin
                booth_state <= 5'd1;
                booth_accumulator <= 5'd0;
                booth_done <= 1'b0;
            end else if (booth_state != 5'd0 && !booth_done) begin
                booth_state <= booth_next_state;
                
                // Booth algorithm implementation
                case (booth_state)
                    5'd1: begin
                        // Check LSB and LSB-1 of multiplier
                        case ({booth_multiplier[0], 1'b0})
                            2'b00: booth_accumulator <= booth_accumulator;
                            2'b01: booth_accumulator <= booth_accumulator + booth_multiplicand;
                            2'b10: booth_accumulator <= booth_accumulator - booth_multiplicand;
                            2'b11: booth_accumulator <= booth_accumulator;
                        endcase
                        booth_multiplier <= {booth_multiplier[4:1], 1'b0};
                        booth_multiplicand <= {booth_multiplicand[3:0], 1'b0};
                    end
                    5'd2: begin
                        case ({booth_multiplier[0], 1'b0})
                            2'b00: booth_accumulator <= booth_accumulator;
                            2'b01: booth_accumulator <= booth_accumulator + booth_multiplicand;
                            2'b10: booth_accumulator <= booth_accumulator - booth_multiplicand;
                            2'b11: booth_accumulator <= booth_accumulator;
                        endcase
                        booth_multiplier <= {booth_multiplier[4:1], 1'b0};
                        booth_multiplicand <= {booth_multiplicand[3:0], 1'b0};
                    end
                    5'd3: begin
                        case ({booth_multiplier[0], 1'b0})
                            2'b00: booth_accumulator <= booth_accumulator;
                            2'b01: booth_accumulator <= booth_accumulator + booth_multiplicand;
                            2'b10: booth_accumulator <= booth_accumulator - booth_multiplicand;
                            2'b11: booth_accumulator <= booth_accumulator;
                        endcase
                        booth_multiplier <= {booth_multiplier[4:1], 1'b0};
                        booth_multiplicand <= {booth_multiplicand[3:0], 1'b0};
                    end
                    5'd4: begin
                        case ({booth_multiplier[0], 1'b0})
                            2'b00: booth_accumulator <= booth_accumulator;
                            2'b01: booth_accumulator <= booth_accumulator + booth_multiplicand;
                            2'b10: booth_accumulator <= booth_accumulator - booth_multiplicand;
                            2'b11: booth_accumulator <= booth_accumulator;
                        endcase
                        booth_multiplier <= {booth_multiplier[4:1], 1'b0};
                        booth_multiplicand <= {booth_multiplicand[3:0], 1'b0};
                    end
                    5'd5: begin
                        case ({booth_multiplier[0], 1'b0})
                            2'b00: booth_accumulator <= booth_accumulator;
                            2'b01: booth_accumulator <= booth_accumulator + booth_multiplicand;
                            2'b10: booth_accumulator <= booth_accumulator - booth_multiplicand;
                            2'b11: booth_accumulator <= booth_accumulator;
                        endcase
                        booth_done <= 1'b1;
                        booth_result <= booth_accumulator;
                    end
                    default: booth_state <= 5'd0;
                endcase
            end
        end
    
    // Next state logic
    always @(*) begin
        next_state = state;
        casez ({state, coin_reg})
            {5'd0, 2'b01}: next_state = 5'd5;
            {5'd0, 2'b10}: next_state = 5'd10;
            {5'd0, 2'b11}: next_state = 5'd25;
            {5'd5, 2'b01}: next_state = 5'd10;
            {5'd5, 2'b10}: next_state = 5'd15;
            {5'd5, 2'b11}: next_state = 5'd30;
            {5'd10, 2'b01}: next_state = 5'd15;
            {5'd10, 2'b10}: next_state = 5'd20;
            {5'd10, 2'b11}: next_state = 5'd0;
            {5'd15, 2'b01}: next_state = 5'd20;
            {5'd15, 2'b10}: next_state = 5'd25;
            {5'd15, 2'b11}: next_state = 5'd0;
            {5'd20, 2'b??}: next_state = 5'd0;
            {5'd25, 2'b??}: next_state = 5'd0;
            {5'd30, 2'b??}: next_state = 5'd0;
            default: next_state = state;
        endcase
        
        // Booth next state logic
        booth_next_state = booth_state;
        if (booth_state != 5'd0 && booth_state < 5'd5) begin
            booth_next_state = booth_state + 5'd1;
        end else if (booth_state == 5'd5) begin
            booth_next_state = 5'd0;
        end
    end
    
    // Output logic
    always @(*) begin
        s_axis_tready = !m_axis_tvalid || (m_axis_tvalid && m_axis_tready);
        
        if (state >= 5'd20 && state < 5'd30 && coin_reg != 2'b00) begin
            m_axis_tvalid = !dispense_reg;
        end else if (state >= 5'd30) begin
            m_axis_tvalid = !dispense_reg;
        end else begin
            m_axis_tvalid = 1'b0;
        end
        
        m_axis_tdata = 1'b1;
        m_axis_tlast = 1'b1;
    end
    
endmodule