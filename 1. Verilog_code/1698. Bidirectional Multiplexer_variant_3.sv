//SystemVerilog
module bidir_mux #(
    parameter DATA_WIDTH = 8
)(
    input  wire                     clk,
    input  wire                     rst_n,
    inout  wire [DATA_WIDTH-1:0]    port_a,
    inout  wire [DATA_WIDTH-1:0]    port_b,
    input  wire                     direction,
    input  wire                     enable
);

    // Internal control signals
    wire a_enable;
    wire b_enable;
    
    // Data path registers
    reg [DATA_WIDTH-1:0] a_in_reg;
    reg [DATA_WIDTH-1:0] b_in_reg;
    reg [DATA_WIDTH-1:0] a_out_reg;
    reg [DATA_WIDTH-1:0] b_out_reg;
    
    // Control logic with explicit AND gates
    wire enable_n;
    wire direction_n;
    
    assign enable_n = ~enable;
    assign direction_n = ~direction;
    
    assign a_enable = ~(enable_n | direction);
    assign b_enable = ~(enable_n | direction_n);
    
    // Input path pipeline
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            a_in_reg <= {DATA_WIDTH{1'b0}};
            b_in_reg <= {DATA_WIDTH{1'b0}};
        end else begin
            a_in_reg <= port_a;
            b_in_reg <= port_b;
        end
    end
    
    // Output path pipeline
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            a_out_reg <= {DATA_WIDTH{1'b0}};
            b_out_reg <= {DATA_WIDTH{1'b0}};
        end else begin
            a_out_reg <= b_in_reg;
            b_out_reg <= a_in_reg;
        end
    end
    
    // Tri-state output control with explicit multiplexers
    wire [DATA_WIDTH-1:0] port_a_mux;
    wire [DATA_WIDTH-1:0] port_b_mux;
    
    assign port_a_mux = a_enable ? a_out_reg : {DATA_WIDTH{1'bz}};
    assign port_b_mux = b_enable ? b_out_reg : {DATA_WIDTH{1'bz}};
    
    assign port_a = port_a_mux;
    assign port_b = port_b_mux;

endmodule