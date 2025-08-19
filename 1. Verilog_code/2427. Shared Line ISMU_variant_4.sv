//SystemVerilog
module shared_line_ismu(
    input clock, resetn,
    input [3:0] device_interrupts,
    input [7:0] line_assignment, // 2-bit per device
    output reg [1:0] irq_lines
);
    // Registered inputs to reduce input-to-first-register delay
    reg [3:0] device_interrupts_r;
    reg [7:0] line_assignment_r;
    
    // Split the combinational logic into two pipeline stages
    reg [3:0] device_line_map[0:1]; // Store which devices map to each line
    reg [1:0] irq_lines_comb;
    
    // Stage 1: Register input signals
    always @(posedge clock or negedge resetn) begin
        if (!resetn) begin
            device_interrupts_r <= 4'b0000;
            line_assignment_r <= 8'b00000000;
        end else begin
            device_interrupts_r <= device_interrupts;
            line_assignment_r <= line_assignment;
        end
    end
    
    // Stage 2: Calculate device-to-line mapping (pipeline register)
    // This splits the critical path by separating mapping from interrupt detection
    always @(posedge clock or negedge resetn) begin
        if (!resetn) begin
            device_line_map[0] <= 4'b0000;
            device_line_map[1] <= 4'b0000;
        end else begin
            // Clear maps
            device_line_map[0] <= 4'b0000;
            device_line_map[1] <= 4'b0000;
            
            // For each device, record which interrupt line it belongs to
            device_line_map[line_assignment_r[1:0]][0] <= 1'b1;
            device_line_map[line_assignment_r[3:2]][1] <= 1'b1;
            device_line_map[line_assignment_r[5:4]][2] <= 1'b1;
            device_line_map[line_assignment_r[7:6]][3] <= 1'b1;
        end
    end
    
    // Stage 3: Compute interrupt lines based on active devices and mapping
    always @(*) begin
        // Shorter combinational path - just AND and OR operations
        irq_lines_comb[0] = (device_interrupts_r[0] && device_line_map[0][0]) ||
                           (device_interrupts_r[1] && device_line_map[0][1]) ||
                           (device_interrupts_r[2] && device_line_map[0][2]) ||
                           (device_interrupts_r[3] && device_line_map[0][3]);
                           
        irq_lines_comb[1] = (device_interrupts_r[0] && device_line_map[1][0]) ||
                           (device_interrupts_r[1] && device_line_map[1][1]) ||
                           (device_interrupts_r[2] && device_line_map[1][2]) ||
                           (device_interrupts_r[3] && device_line_map[1][3]);
    end
    
    // Stage 4: Output register
    always @(posedge clock or negedge resetn) begin
        if (!resetn) begin
            irq_lines <= 2'b00;
        end else begin
            irq_lines <= irq_lines_comb;
        end
    end
endmodule