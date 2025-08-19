module shadow_regfile #(
    parameter WIDTH = 32,
    parameter ADDR_BITS = 4,
    parameter REG_COUNT = 2**ADDR_BITS
)(
    input  wire                 clock,
    input  wire                 resetn,        // Active low reset
    input  wire                 write_en,
    input  wire [ADDR_BITS-1:0] write_addr,
    input  wire [WIDTH-1:0]     write_data,
    input  wire [ADDR_BITS-1:0] read_addr,
    output wire [WIDTH-1:0]     read_data,
    
    // Shadow register controls
    input  wire                 shadow_load,   // Copy main to shadow
    input  wire                 shadow_swap,   // Swap main and shadow
    input  wire                 use_shadow,    // Read from shadow instead of main
    output wire [WIDTH-1:0]     shadow_data    // Output from shadow register
);
    // Main register file
    reg [WIDTH-1:0] main_regs [0:REG_COUNT-1];
    
    // Shadow register file
    reg [WIDTH-1:0] shadow_regs [0:REG_COUNT-1];
    
    // Read outputs - select between main and shadow based on use_shadow
    assign read_data = use_shadow ? shadow_regs[read_addr] : main_regs[read_addr];
    assign shadow_data = shadow_regs[read_addr];
    
    integer i;
    always @(posedge clock or negedge resetn) begin
        if (!resetn) begin
            // Reset both main and shadow registers
            for (i = 0; i < REG_COUNT; i = i + 1) begin
                main_regs[i] <= {WIDTH{1'b0}};
                shadow_regs[i] <= {WIDTH{1'b0}};
            end
        end
        else begin
            // Normal write operation to main registers
            if (write_en) begin
                main_regs[write_addr] <= write_data;
            end
            
            // Shadow operations
            if (shadow_load) begin
                // Load all shadow registers from main
                for (i = 0; i < REG_COUNT; i = i + 1) begin
                    shadow_regs[i] <= main_regs[i];
                end
            end
            else if (shadow_swap) begin
                // Swap main and shadow registers
                for (i = 0; i < REG_COUNT; i = i + 1) begin
                    shadow_regs[i] <= main_regs[i];
                    main_regs[i] <= shadow_regs[i];
                end
            end
        end
    end
endmodule