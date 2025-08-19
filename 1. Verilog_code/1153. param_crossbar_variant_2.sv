//SystemVerilog

module param_crossbar #(
    parameter PORTS = 4,
    parameter WIDTH = 8
)(
    input wire clock, reset,
    input wire [WIDTH-1:0] in [0:PORTS-1],
    input wire [$clog2(PORTS)-1:0] sel [0:PORTS-1],
    input wire enable,
    output reg [WIDTH-1:0] out [0:PORTS-1]
);
    // Flexible crossbar with configurable ports and widths
    
    // Selected input data for each output port
    wire [WIDTH-1:0] selected_data [0:PORTS-1];
    
    // Registered selection signals for improved timing
    reg [$clog2(PORTS)-1:0] sel_reg [0:PORTS-1];
    reg enable_reg;
    
    // Index registers for processing
    reg [2:0] idx_first_half, idx_second_half;
    
    // Register enable signal
    always @(posedge clock) begin
        if (reset)
            enable_reg <= 1'b0;
        else
            enable_reg <= enable;
    end
    
    // Register selection signals
    integer j;
    always @(posedge clock) begin
        if (reset) begin
            for (j = 0; j < PORTS; j = j + 1)
                sel_reg[j] <= 0;
        end
        else begin
            for (j = 0; j < PORTS; j = j + 1)
                sel_reg[j] <= sel[j];
        end
    end
    
    // Move register from output to input selection logic
    // Selecting input data using registered select signals
    genvar i;
    generate
        for (i = 0; i < PORTS; i = i + 1) begin : data_select
            assign selected_data[i] = in[sel_reg[i]];
        end
    endgenerate
    
    // Reset logic for first half of ports
    always @(posedge clock) begin
        if (reset) begin
            for (j = 0; j < PORTS/2; j = j + 1)
                out[j] <= {WIDTH{1'b0}};
        end
    end
    
    // Reset logic for second half of ports
    always @(posedge clock) begin
        if (reset) begin
            for (j = PORTS/2; j < PORTS; j = j + 1)
                out[j] <= {WIDTH{1'b0}};
        end
    end
    
    // Update logic for first half of ports
    always @(posedge clock) begin
        if (!reset && enable_reg) begin
            for (j = 0; j < PORTS/2; j = j + 1)
                out[j] <= selected_data[j];
        end
    end
    
    // Update logic for second half of ports
    always @(posedge clock) begin
        if (!reset && enable_reg) begin
            for (j = PORTS/2; j < PORTS; j = j + 1)
                out[j] <= selected_data[j];
        end
    end
    
    // Update index for first half
    always @(posedge clock) begin
        if (reset)
            idx_first_half <= 0;
        else if (enable_reg)
            idx_first_half <= PORTS/2;
    end
    
    // Update index for second half
    always @(posedge clock) begin
        if (reset)
            idx_second_half <= 0;
        else if (enable_reg)
            idx_second_half <= PORTS;
    end
endmodule