//SystemVerilog
//IEEE 1364-2005 Verilog
module tdm_crossbar (
    input wire clock, reset,
    
    // Input interface with valid-ready handshake
    input wire [7:0] in0, in1, in2, in3,
    input wire in0_valid, in1_valid, in2_valid, in3_valid,
    output wire in0_ready, in1_ready, in2_ready, in3_ready,
    
    // Output interface with valid-ready handshake
    output reg [7:0] out0, out1, out2, out3,
    output reg out0_valid, out1_valid, out2_valid, out3_valid,
    input wire out0_ready, out1_ready, out2_ready, out3_ready
);
    // Time-division multiplexed crossbar using fixed schedule
    reg [1:0] time_slot;
    
    // Registered inputs to improve timing at input stage
    reg [7:0] in0_reg, in1_reg, in2_reg, in3_reg;
    reg in0_valid_reg, in1_valid_reg, in2_valid_reg, in3_valid_reg;
    
    // Input FIFOs state
    reg in0_pending, in1_pending, in2_pending, in3_pending;
    
    // Next state values
    reg [7:0] next_out0, next_out1, next_out2, next_out3;
    reg next_out0_valid, next_out1_valid, next_out2_valid, next_out3_valid;
    
    // Generate ready signals - data is accepted when valid and not pending
    assign in0_ready = !in0_pending || (in0_pending && in0_valid_reg && can_process(time_slot, 0));
    assign in1_ready = !in1_pending || (in1_pending && in1_valid_reg && can_process(time_slot, 1));
    assign in2_ready = !in2_pending || (in2_pending && in2_valid_reg && can_process(time_slot, 2));
    assign in3_ready = !in3_pending || (in3_pending && in3_valid_reg && can_process(time_slot, 3));
    
    // Helper function to determine if an input can be processed in the current time slot
    function can_process;
        input [1:0] slot;
        input [1:0] port;
        begin
            case (slot)
                2'b00: can_process = (port == 0);
                2'b01: can_process = (port == 3);
                2'b10: can_process = (port == 2);
                2'b11: can_process = (port == 1);
                default: can_process = 1'b0;
            endcase
        end
    endfunction
    
    // Register inputs and track pending status
    always @(posedge clock or posedge reset) begin
        if (reset) begin
            in0_reg <= 8'h00;
            in1_reg <= 8'h00;
            in2_reg <= 8'h00;
            in3_reg <= 8'h00;
            in0_valid_reg <= 1'b0;
            in1_valid_reg <= 1'b0;
            in2_valid_reg <= 1'b0;
            in3_valid_reg <= 1'b0;
            in0_pending <= 1'b0;
            in1_pending <= 1'b0;
            in2_pending <= 1'b0;
            in3_pending <= 1'b0;
        end else begin
            // Input 0 logic
            if (in0_valid && in0_ready) begin
                in0_reg <= in0;
                in0_valid_reg <= 1'b1;
                in0_pending <= 1'b1;
            end else if (in0_valid_reg && can_process(time_slot, 0)) begin
                in0_pending <= 1'b0;
                in0_valid_reg <= 1'b0;
            end
            
            // Input 1 logic
            if (in1_valid && in1_ready) begin
                in1_reg <= in1;
                in1_valid_reg <= 1'b1;
                in1_pending <= 1'b1;
            end else if (in1_valid_reg && can_process(time_slot, 1)) begin
                in1_pending <= 1'b0;
                in1_valid_reg <= 1'b0;
            end
            
            // Input 2 logic
            if (in2_valid && in2_ready) begin
                in2_reg <= in2;
                in2_valid_reg <= 1'b1;
                in2_pending <= 1'b1;
            end else if (in2_valid_reg && can_process(time_slot, 2)) begin
                in2_pending <= 1'b0;
                in2_valid_reg <= 1'b0;
            end
            
            // Input 3 logic
            if (in3_valid && in3_ready) begin
                in3_reg <= in3;
                in3_valid_reg <= 1'b1;
                in3_pending <= 1'b1;
            end else if (in3_valid_reg && can_process(time_slot, 3)) begin
                in3_pending <= 1'b0;
                in3_valid_reg <= 1'b0;
            end
        end
    end
    
    // Time slot counter
    always @(posedge clock or posedge reset) begin
        if (reset)
            time_slot <= 2'b00;
        else
            time_slot <= time_slot + 1'b1;
    end
    
    // Crossbar routing logic (combinational)
    always @(*) begin
        // Default values
        next_out0 = out0;
        next_out1 = out1;
        next_out2 = out2;
        next_out3 = out3;
        next_out0_valid = 1'b0;
        next_out1_valid = 1'b0;
        next_out2_valid = 1'b0;
        next_out3_valid = 1'b0;
        
        case (time_slot)
            2'b00: begin
                if (in0_valid_reg) begin
                    next_out0 = in0_reg;
                    next_out0_valid = 1'b1;
                end
                if (in1_valid_reg) begin
                    next_out1 = in1_reg;
                    next_out1_valid = 1'b1;
                end
                if (in2_valid_reg) begin
                    next_out2 = in2_reg;
                    next_out2_valid = 1'b1;
                end
                if (in3_valid_reg) begin
                    next_out3 = in3_reg;
                    next_out3_valid = 1'b1;
                end
            end
            2'b01: begin
                if (in3_valid_reg) begin
                    next_out0 = in3_reg;
                    next_out0_valid = 1'b1;
                end
                if (in0_valid_reg) begin
                    next_out1 = in0_reg;
                    next_out1_valid = 1'b1;
                end
                if (in1_valid_reg) begin
                    next_out2 = in1_reg;
                    next_out2_valid = 1'b1;
                end
                if (in2_valid_reg) begin
                    next_out3 = in2_reg;
                    next_out3_valid = 1'b1;
                end
            end
            2'b10: begin
                if (in2_valid_reg) begin
                    next_out0 = in2_reg;
                    next_out0_valid = 1'b1;
                end
                if (in3_valid_reg) begin
                    next_out1 = in3_reg;
                    next_out1_valid = 1'b1;
                end
                if (in0_valid_reg) begin
                    next_out2 = in0_reg;
                    next_out2_valid = 1'b1;
                end
                if (in1_valid_reg) begin
                    next_out3 = in1_reg;
                    next_out3_valid = 1'b1;
                end
            end
            2'b11: begin
                if (in1_valid_reg) begin
                    next_out0 = in1_reg;
                    next_out0_valid = 1'b1;
                end
                if (in2_valid_reg) begin
                    next_out1 = in2_reg;
                    next_out1_valid = 1'b1;
                end
                if (in3_valid_reg) begin
                    next_out2 = in3_reg;
                    next_out2_valid = 1'b1;
                end
                if (in0_valid_reg) begin
                    next_out3 = in0_reg;
                    next_out3_valid = 1'b1;
                end
            end
            default: begin
                next_out0 = 8'h00;
                next_out1 = 8'h00;
                next_out2 = 8'h00;
                next_out3 = 8'h00;
                next_out0_valid = 1'b0;
                next_out1_valid = 1'b0;
                next_out2_valid = 1'b0;
                next_out3_valid = 1'b0;
            end
        endcase
    end
    
    // Output registers with handshaking
    always @(posedge clock or posedge reset) begin
        if (reset) begin
            out0 <= 8'h00;
            out1 <= 8'h00;
            out2 <= 8'h00;
            out3 <= 8'h00;
            out0_valid <= 1'b0;
            out1_valid <= 1'b0;
            out2_valid <= 1'b0;
            out3_valid <= 1'b0;
        end else begin
            // Output 0 logic
            if (!out0_valid || out0_ready) begin
                out0 <= next_out0;
                out0_valid <= next_out0_valid;
            end
            
            // Output 1 logic
            if (!out1_valid || out1_ready) begin
                out1 <= next_out1;
                out1_valid <= next_out1_valid;
            end
            
            // Output 2 logic
            if (!out2_valid || out2_ready) begin
                out2 <= next_out2;
                out2_valid <= next_out2_valid;
            end
            
            // Output 3 logic
            if (!out3_valid || out3_ready) begin
                out3 <= next_out3;
                out3_valid <= next_out3_valid;
            end
        end
    end
endmodule