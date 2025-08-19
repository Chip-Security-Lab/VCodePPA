//SystemVerilog
module shadow_regfile #(
    parameter WIDTH = 32,
    parameter ADDR_BITS = 4,
    parameter REG_COUNT = 2**ADDR_BITS
)(
    input  wire                 clock,
    input  wire                 resetn,
    input  wire                 write_en,
    input  wire [ADDR_BITS-1:0] write_addr,
    input  wire [WIDTH-1:0]     write_data,
    input  wire [ADDR_BITS-1:0] read_addr,
    output wire [WIDTH-1:0]     read_data,
    input  wire                 shadow_load,
    input  wire                 shadow_swap,
    input  wire                 use_shadow,
    output wire [WIDTH-1:0]     shadow_data
);

    // Pipeline stage 1 registers
    reg [WIDTH-1:0] main_regs_stage1 [0:REG_COUNT-1];
    reg [WIDTH-1:0] shadow_regs_stage1 [0:REG_COUNT-1];
    reg [WIDTH-1:0] main_regs_buf_stage1 [0:REG_COUNT-1];
    reg [WIDTH-1:0] shadow_regs_buf_stage1 [0:REG_COUNT-1];
    reg shadow_load_stage1, shadow_swap_stage1;
    reg [ADDR_BITS-1:0] write_addr_stage1;
    reg [WIDTH-1:0] write_data_stage1;
    reg write_en_stage1;

    // Pipeline stage 2 registers
    reg [WIDTH-1:0] main_regs_stage2 [0:REG_COUNT-1];
    reg [WIDTH-1:0] shadow_regs_stage2 [0:REG_COUNT-1];
    reg [WIDTH-1:0] main_regs_buf_stage2 [0:REG_COUNT-1];
    reg [WIDTH-1:0] shadow_regs_buf_stage2 [0:REG_COUNT-1];
    reg shadow_load_stage2, shadow_swap_stage2;
    reg [ADDR_BITS-1:0] write_addr_stage2;
    reg [WIDTH-1:0] write_data_stage2;
    reg write_en_stage2;

    // Pipeline stage 3 registers
    reg [WIDTH-1:0] main_regs_stage3 [0:REG_COUNT-1];
    reg [WIDTH-1:0] shadow_regs_stage3 [0:REG_COUNT-1];
    reg [WIDTH-1:0] main_regs_buf_stage3 [0:REG_COUNT-1];
    reg [WIDTH-1:0] shadow_regs_buf_stage3 [0:REG_COUNT-1];
    reg [ADDR_BITS-1:0] read_addr_stage3;
    reg use_shadow_stage3;

    // Output registers
    reg [WIDTH-1:0] read_data_reg;
    reg [WIDTH-1:0] shadow_data_reg;

    // Stage 1: Input sampling and initial processing
    always @(posedge clock or negedge resetn) begin
        if (!resetn) begin
            for (integer i = 0; i < REG_COUNT; i = i + 1) begin
                main_regs_stage1[i] <= {WIDTH{1'b0}};
                shadow_regs_stage1[i] <= {WIDTH{1'b0}};
                main_regs_buf_stage1[i] <= {WIDTH{1'b0}};
                shadow_regs_buf_stage1[i] <= {WIDTH{1'b0}};
            end
            shadow_load_stage1 <= 1'b0;
            shadow_swap_stage1 <= 1'b0;
            write_addr_stage1 <= {ADDR_BITS{1'b0}};
            write_data_stage1 <= {WIDTH{1'b0}};
            write_en_stage1 <= 1'b0;
        end else begin
            shadow_load_stage1 <= shadow_load;
            shadow_swap_stage1 <= shadow_swap;
            write_addr_stage1 <= write_addr;
            write_data_stage1 <= write_data;
            write_en_stage1 <= write_en;
            
            if (write_en) begin
                main_regs_buf_stage1[write_addr] <= write_data;
            end
        end
    end

    // Stage 2: Shadow operations
    always @(posedge clock or negedge resetn) begin
        if (!resetn) begin
            for (integer i = 0; i < REG_COUNT; i = i + 1) begin
                main_regs_stage2[i] <= {WIDTH{1'b0}};
                shadow_regs_stage2[i] <= {WIDTH{1'b0}};
                main_regs_buf_stage2[i] <= {WIDTH{1'b0}};
                shadow_regs_buf_stage2[i] <= {WIDTH{1'b0}};
            end
            shadow_load_stage2 <= 1'b0;
            shadow_swap_stage2 <= 1'b0;
            write_addr_stage2 <= {ADDR_BITS{1'b0}};
            write_data_stage2 <= {WIDTH{1'b0}};
            write_en_stage2 <= 1'b0;
        end else begin
            shadow_load_stage2 <= shadow_load_stage1;
            shadow_swap_stage2 <= shadow_swap_stage1;
            write_addr_stage2 <= write_addr_stage1;
            write_data_stage2 <= write_data_stage1;
            write_en_stage2 <= write_en_stage1;
            
            if (shadow_load_stage1) begin
                for (integer i = 0; i < REG_COUNT; i = i + 1) begin
                    shadow_regs_buf_stage2[i] <= main_regs_buf_stage1[i];
                end
            end else if (shadow_swap_stage1) begin
                for (integer i = 0; i < REG_COUNT; i = i + 1) begin
                    shadow_regs_buf_stage2[i] <= main_regs_buf_stage1[i];
                    main_regs_buf_stage2[i] <= shadow_regs_stage1[i];
                end
            end
        end
    end

    // Stage 3: Register updates and read operations
    always @(posedge clock or negedge resetn) begin
        if (!resetn) begin
            for (integer i = 0; i < REG_COUNT; i = i + 1) begin
                main_regs_stage3[i] <= {WIDTH{1'b0}};
                shadow_regs_stage3[i] <= {WIDTH{1'b0}};
                main_regs_buf_stage3[i] <= {WIDTH{1'b0}};
                shadow_regs_buf_stage3[i] <= {WIDTH{1'b0}};
            end
            read_addr_stage3 <= {ADDR_BITS{1'b0}};
            use_shadow_stage3 <= 1'b0;
        end else begin
            read_addr_stage3 <= read_addr;
            use_shadow_stage3 <= use_shadow;
            
            for (integer i = 0; i < REG_COUNT; i = i + 1) begin
                main_regs_stage3[i] <= main_regs_buf_stage2[i];
                shadow_regs_stage3[i] <= shadow_regs_buf_stage2[i];
            end
        end
    end

    // Output stage
    always @(posedge clock or negedge resetn) begin
        if (!resetn) begin
            read_data_reg <= {WIDTH{1'b0}};
            shadow_data_reg <= {WIDTH{1'b0}};
        end else begin
            read_data_reg <= use_shadow_stage3 ? shadow_regs_stage3[read_addr_stage3] : main_regs_stage3[read_addr_stage3];
            shadow_data_reg <= shadow_regs_stage3[read_addr_stage3];
        end
    end

    assign read_data = read_data_reg;
    assign shadow_data = shadow_data_reg;

endmodule