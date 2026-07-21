export type Json =
  | string
  | number
  | boolean
  | null
  | { [key: string]: Json | undefined }
  | Json[]

export type Database = {
  // Allows to automatically instantiate createClient with right options
  // instead of createClient<Database, { PostgrestVersion: 'XX' }>(URL, KEY)
  __InternalSupabase: {
    PostgrestVersion: "14.5"
  }
  graphql_public: {
    Tables: {
      [_ in never]: never
    }
    Views: {
      [_ in never]: never
    }
    Functions: {
      graphql: {
        Args: {
          extensions?: Json
          operationName?: string
          query?: string
          variables?: Json
        }
        Returns: Json
      }
    }
    Enums: {
      [_ in never]: never
    }
    CompositeTypes: {
      [_ in never]: never
    }
  }
  public: {
    Tables: {
      arboles: {
        Row: {
          activo: boolean
          altura_cm: number | null
          codigo: string
          creado_en: string
          especie_id: string
          fecha_plantacion: string | null
          frecuencia_dias_override: number | null
          id: string
          lat: number | null
          lng: number | null
          nombre: string | null
          notas: string | null
          sector: string | null
        }
        Insert: {
          activo?: boolean
          altura_cm?: number | null
          codigo: string
          creado_en?: string
          especie_id: string
          fecha_plantacion?: string | null
          frecuencia_dias_override?: number | null
          id?: string
          lat?: number | null
          lng?: number | null
          nombre?: string | null
          notas?: string | null
          sector?: string | null
        }
        Update: {
          activo?: boolean
          altura_cm?: number | null
          codigo?: string
          creado_en?: string
          especie_id?: string
          fecha_plantacion?: string | null
          frecuencia_dias_override?: number | null
          id?: string
          lat?: number | null
          lng?: number | null
          nombre?: string | null
          notas?: string | null
          sector?: string | null
        }
        Relationships: [
          {
            foreignKeyName: "arboles_especie_id_fkey"
            columns: ["especie_id"]
            isOneToOne: false
            referencedRelation: "especies"
            referencedColumns: ["id"]
          },
        ]
      }
      clima_diario: {
        Row: {
          creado_en: string
          et0_mm: number
          fecha: string
          lluvia_mm: number
          temp_max: number | null
        }
        Insert: {
          creado_en?: string
          et0_mm?: number
          fecha: string
          lluvia_mm?: number
          temp_max?: number | null
        }
        Update: {
          creado_en?: string
          et0_mm?: number
          fecha?: string
          lluvia_mm?: number
          temp_max?: number | null
        }
        Relationships: []
      }
      config: {
        Row: {
          clave: string
          descripcion: string | null
          valor: Json
        }
        Insert: {
          clave: string
          descripcion?: string | null
          valor: Json
        }
        Update: {
          clave?: string
          descripcion?: string | null
          valor?: Json
        }
        Relationships: []
      }
      especies: {
        Row: {
          creado_en: string
          en_programa: boolean
          frecuencia_dias: number
          id: string
          nombre_cientifico: string
          nombre_comun: string
          ref_plano: string | null
        }
        Insert: {
          creado_en?: string
          en_programa?: boolean
          frecuencia_dias: number
          id?: string
          nombre_cientifico: string
          nombre_comun: string
          ref_plano?: string | null
        }
        Update: {
          creado_en?: string
          en_programa?: boolean
          frecuencia_dias?: number
          id?: string
          nombre_cientifico?: string
          nombre_comun?: string
          ref_plano?: string | null
        }
        Relationships: []
      }
      insignias: {
        Row: {
          activa: boolean
          copy_desbloqueo: string
          criterio: Json | null
          es_pin: boolean
          id: string
          nombre: string
          orden: number | null
          tipo: Database["public"]["Enums"]["tipo_insignia"]
          umbral_puntos: number | null
        }
        Insert: {
          activa?: boolean
          copy_desbloqueo: string
          criterio?: Json | null
          es_pin?: boolean
          id: string
          nombre: string
          orden?: number | null
          tipo: Database["public"]["Enums"]["tipo_insignia"]
          umbral_puntos?: number | null
        }
        Update: {
          activa?: boolean
          copy_desbloqueo?: string
          criterio?: Json | null
          es_pin?: boolean
          id?: string
          nombre?: string
          orden?: number | null
          tipo?: Database["public"]["Enums"]["tipo_insignia"]
          umbral_puntos?: number | null
        }
        Relationships: []
      }
      insignias_ganadas: {
        Row: {
          canje_estado: Database["public"]["Enums"]["estado_canje"]
          canje_token: string
          canjeada_en: string | null
          canjeada_por: string | null
          ganada_en: string
          id: string
          insignia_id: string
          perfil_id: string
        }
        Insert: {
          canje_estado?: Database["public"]["Enums"]["estado_canje"]
          canje_token?: string
          canjeada_en?: string | null
          canjeada_por?: string | null
          ganada_en?: string
          id?: string
          insignia_id: string
          perfil_id: string
        }
        Update: {
          canje_estado?: Database["public"]["Enums"]["estado_canje"]
          canje_token?: string
          canjeada_en?: string | null
          canjeada_por?: string | null
          ganada_en?: string
          id?: string
          insignia_id?: string
          perfil_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "insignias_ganadas_canjeada_por_fkey"
            columns: ["canjeada_por"]
            isOneToOne: false
            referencedRelation: "perfiles"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "insignias_ganadas_canjeada_por_fkey"
            columns: ["canjeada_por"]
            isOneToOne: false
            referencedRelation: "v_ranking"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "insignias_ganadas_insignia_id_fkey"
            columns: ["insignia_id"]
            isOneToOne: false
            referencedRelation: "insignias"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "insignias_ganadas_perfil_id_fkey"
            columns: ["perfil_id"]
            isOneToOne: false
            referencedRelation: "perfiles"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "insignias_ganadas_perfil_id_fkey"
            columns: ["perfil_id"]
            isOneToOne: false
            referencedRelation: "v_ranking"
            referencedColumns: ["id"]
          },
        ]
      }
      perfiles: {
        Row: {
          cambios_nombre: number
          creado_en: string
          es_admin: boolean
          id: string
          nombre: string
          puntos: number
        }
        Insert: {
          cambios_nombre?: number
          creado_en?: string
          es_admin?: boolean
          id: string
          nombre: string
          puntos?: number
        }
        Update: {
          cambios_nombre?: number
          creado_en?: string
          es_admin?: boolean
          id?: string
          nombre?: string
          puntos?: number
        }
        Relationships: []
      }
      reportes: {
        Row: {
          arbol_id: string
          creado_en: string
          descripcion: string | null
          estado: Database["public"]["Enums"]["estado_reporte"]
          id: string
          perfil_id: string
          puntos: number
          resuelto_en: string | null
          resuelto_por: string | null
          tipo: Database["public"]["Enums"]["tipo_reporte"]
        }
        Insert: {
          arbol_id: string
          creado_en?: string
          descripcion?: string | null
          estado?: Database["public"]["Enums"]["estado_reporte"]
          id?: string
          perfil_id: string
          puntos?: number
          resuelto_en?: string | null
          resuelto_por?: string | null
          tipo: Database["public"]["Enums"]["tipo_reporte"]
        }
        Update: {
          arbol_id?: string
          creado_en?: string
          descripcion?: string | null
          estado?: Database["public"]["Enums"]["estado_reporte"]
          id?: string
          perfil_id?: string
          puntos?: number
          resuelto_en?: string | null
          resuelto_por?: string | null
          tipo?: Database["public"]["Enums"]["tipo_reporte"]
        }
        Relationships: [
          {
            foreignKeyName: "reportes_arbol_id_fkey"
            columns: ["arbol_id"]
            isOneToOne: false
            referencedRelation: "arboles"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "reportes_arbol_id_fkey"
            columns: ["arbol_id"]
            isOneToOne: false
            referencedRelation: "v_arboles_estado"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "reportes_perfil_id_fkey"
            columns: ["perfil_id"]
            isOneToOne: false
            referencedRelation: "perfiles"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "reportes_perfil_id_fkey"
            columns: ["perfil_id"]
            isOneToOne: false
            referencedRelation: "v_ranking"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "reportes_resuelto_por_fkey"
            columns: ["resuelto_por"]
            isOneToOne: false
            referencedRelation: "perfiles"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "reportes_resuelto_por_fkey"
            columns: ["resuelto_por"]
            isOneToOne: false
            referencedRelation: "v_ranking"
            referencedColumns: ["id"]
          },
        ]
      }
      riegos: {
        Row: {
          arbol_id: string
          creado_en: string
          dispositivo_id: string | null
          estado_al_regar: Database["public"]["Enums"]["estado_arbol"]
          id: string
          lat: number | null
          lng: number | null
          perfil_id: string | null
          puntos: number
        }
        Insert: {
          arbol_id: string
          creado_en?: string
          dispositivo_id?: string | null
          estado_al_regar: Database["public"]["Enums"]["estado_arbol"]
          id?: string
          lat?: number | null
          lng?: number | null
          perfil_id?: string | null
          puntos?: number
        }
        Update: {
          arbol_id?: string
          creado_en?: string
          dispositivo_id?: string | null
          estado_al_regar?: Database["public"]["Enums"]["estado_arbol"]
          id?: string
          lat?: number | null
          lng?: number | null
          perfil_id?: string | null
          puntos?: number
        }
        Relationships: [
          {
            foreignKeyName: "riegos_arbol_id_fkey"
            columns: ["arbol_id"]
            isOneToOne: false
            referencedRelation: "arboles"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "riegos_arbol_id_fkey"
            columns: ["arbol_id"]
            isOneToOne: false
            referencedRelation: "v_arboles_estado"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "riegos_perfil_id_fkey"
            columns: ["perfil_id"]
            isOneToOne: false
            referencedRelation: "perfiles"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "riegos_perfil_id_fkey"
            columns: ["perfil_id"]
            isOneToOne: false
            referencedRelation: "v_ranking"
            referencedColumns: ["id"]
          },
        ]
      }
      secretos: {
        Row: {
          clave: string
          valor: string
        }
        Insert: {
          clave: string
          valor: string
        }
        Update: {
          clave?: string
          valor?: string
        }
        Relationships: []
      }
    }
    Views: {
      v_arboles_estado: {
        Row: {
          activo: boolean | null
          altura_cm: number | null
          codigo: string | null
          creado_en: string | null
          deficit_mm: number | null
          dias_sin_riego: number | null
          especie_cientifico: string | null
          especie_id: string | null
          especie_nombre: string | null
          estado: Database["public"]["Enums"]["estado_arbol"] | null
          f_efectiva: number | null
          fecha_plantacion: string | null
          frecuencia_dias_override: number | null
          id: string | null
          lat: number | null
          lluvia_3d: number | null
          lng: number | null
          nombre: string | null
          notas: string | null
          sector: string | null
        }
        Relationships: [
          {
            foreignKeyName: "arboles_especie_id_fkey"
            columns: ["especie_id"]
            isOneToOne: false
            referencedRelation: "especies"
            referencedColumns: ["id"]
          },
        ]
      }
      v_ranking: {
        Row: {
          id: string | null
          nombre: string | null
          puesto: number | null
          puntos: number | null
          riegos: number | null
        }
        Relationships: []
      }
    }
    Functions: {
      actualizar_mi_nombre: { Args: { p_nombre: string }; Returns: Json }
      canjear_pin: { Args: { p_token: string }; Returns: Json }
      es_admin: { Args: never; Returns: boolean }
      f_deficit_mm: { Args: { p_arbol: string }; Returns: number }
      f_estado_arbol: {
        Args: { p_arbol_id: string }
        Returns: {
          dias_sin_riego: number
          estado: Database["public"]["Enums"]["estado_arbol"]
          f_efectiva: number
        }[]
      }
      mi_progreso: { Args: never; Returns: Json }
      mis_canjes: { Args: never; Returns: Json }
      obtener_clima_token: { Args: never; Returns: Json }
      otorgar_insignias: { Args: { p_perfil: string }; Returns: Json }
      reclamar_riegos: { Args: { p_dispositivo_id: string }; Returns: Json }
      registrar_clima: {
        Args: {
          p_et0: number
          p_fecha: string
          p_lluvia: number
          p_temp?: number
          p_token: string
        }
        Returns: Json
      }
      registrar_riego: {
        Args: {
          p_codigo: string
          p_dispositivo_id?: string
          p_lat?: number
          p_lng?: number
        }
        Returns: Json
      }
      ver_canje: { Args: { p_token: string }; Returns: Json }
    }
    Enums: {
      estado_arbol: "feliz" | "bien" | "sediento" | "muy_sediento"
      estado_canje: "pendiente" | "entregado"
      estado_reporte: "pendiente" | "verificado" | "rechazado"
      tipo_insignia: "escalera" | "merito"
      tipo_reporte: "hormigas" | "plaga" | "rama_rota" | "vandalismo" | "otro"
    }
    CompositeTypes: {
      [_ in never]: never
    }
  }
}

type DatabaseWithoutInternals = Omit<Database, "__InternalSupabase">

type DefaultSchema = DatabaseWithoutInternals[Extract<keyof Database, "public">]

export type Tables<
  DefaultSchemaTableNameOrOptions extends
    | keyof (DefaultSchema["Tables"] & DefaultSchema["Views"])
    | { schema: keyof DatabaseWithoutInternals },
  TableName extends DefaultSchemaTableNameOrOptions extends {
    schema: keyof DatabaseWithoutInternals
  }
    ? keyof (DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Tables"] &
        DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Views"])
    : never = never,
> = DefaultSchemaTableNameOrOptions extends {
  schema: keyof DatabaseWithoutInternals
}
  ? (DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Tables"] &
      DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Views"])[TableName] extends {
      Row: infer R
    }
    ? R
    : never
  : DefaultSchemaTableNameOrOptions extends keyof (DefaultSchema["Tables"] &
        DefaultSchema["Views"])
    ? (DefaultSchema["Tables"] &
        DefaultSchema["Views"])[DefaultSchemaTableNameOrOptions] extends {
        Row: infer R
      }
      ? R
      : never
    : never

export type TablesInsert<
  DefaultSchemaTableNameOrOptions extends
    | keyof DefaultSchema["Tables"]
    | { schema: keyof DatabaseWithoutInternals },
  TableName extends DefaultSchemaTableNameOrOptions extends {
    schema: keyof DatabaseWithoutInternals
  }
    ? keyof DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Tables"]
    : never = never,
> = DefaultSchemaTableNameOrOptions extends {
  schema: keyof DatabaseWithoutInternals
}
  ? DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Tables"][TableName] extends {
      Insert: infer I
    }
    ? I
    : never
  : DefaultSchemaTableNameOrOptions extends keyof DefaultSchema["Tables"]
    ? DefaultSchema["Tables"][DefaultSchemaTableNameOrOptions] extends {
        Insert: infer I
      }
      ? I
      : never
    : never

export type TablesUpdate<
  DefaultSchemaTableNameOrOptions extends
    | keyof DefaultSchema["Tables"]
    | { schema: keyof DatabaseWithoutInternals },
  TableName extends DefaultSchemaTableNameOrOptions extends {
    schema: keyof DatabaseWithoutInternals
  }
    ? keyof DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Tables"]
    : never = never,
> = DefaultSchemaTableNameOrOptions extends {
  schema: keyof DatabaseWithoutInternals
}
  ? DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Tables"][TableName] extends {
      Update: infer U
    }
    ? U
    : never
  : DefaultSchemaTableNameOrOptions extends keyof DefaultSchema["Tables"]
    ? DefaultSchema["Tables"][DefaultSchemaTableNameOrOptions] extends {
        Update: infer U
      }
      ? U
      : never
    : never

export type Enums<
  DefaultSchemaEnumNameOrOptions extends
    | keyof DefaultSchema["Enums"]
    | { schema: keyof DatabaseWithoutInternals },
  EnumName extends DefaultSchemaEnumNameOrOptions extends {
    schema: keyof DatabaseWithoutInternals
  }
    ? keyof DatabaseWithoutInternals[DefaultSchemaEnumNameOrOptions["schema"]]["Enums"]
    : never = never,
> = DefaultSchemaEnumNameOrOptions extends {
  schema: keyof DatabaseWithoutInternals
}
  ? DatabaseWithoutInternals[DefaultSchemaEnumNameOrOptions["schema"]]["Enums"][EnumName]
  : DefaultSchemaEnumNameOrOptions extends keyof DefaultSchema["Enums"]
    ? DefaultSchema["Enums"][DefaultSchemaEnumNameOrOptions]
    : never

export type CompositeTypes<
  PublicCompositeTypeNameOrOptions extends
    | keyof DefaultSchema["CompositeTypes"]
    | { schema: keyof DatabaseWithoutInternals },
  CompositeTypeName extends PublicCompositeTypeNameOrOptions extends {
    schema: keyof DatabaseWithoutInternals
  }
    ? keyof DatabaseWithoutInternals[PublicCompositeTypeNameOrOptions["schema"]]["CompositeTypes"]
    : never = never,
> = PublicCompositeTypeNameOrOptions extends {
  schema: keyof DatabaseWithoutInternals
}
  ? DatabaseWithoutInternals[PublicCompositeTypeNameOrOptions["schema"]]["CompositeTypes"][CompositeTypeName]
  : PublicCompositeTypeNameOrOptions extends keyof DefaultSchema["CompositeTypes"]
    ? DefaultSchema["CompositeTypes"][PublicCompositeTypeNameOrOptions]
    : never

export const Constants = {
  graphql_public: {
    Enums: {},
  },
  public: {
    Enums: {
      estado_arbol: ["feliz", "bien", "sediento", "muy_sediento"],
      estado_canje: ["pendiente", "entregado"],
      estado_reporte: ["pendiente", "verificado", "rechazado"],
      tipo_insignia: ["escalera", "merito"],
      tipo_reporte: ["hormigas", "plaga", "rama_rota", "vandalismo", "otro"],
    },
  },
} as const
